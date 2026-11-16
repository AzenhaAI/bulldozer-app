// Anonymous daily usage counters for Azenha AI apps.
//
// Canonical copy: ~/Projects/_stores/usage/dart/usage_stats.dart. Each app
// keeps an identical copy in lib/usage_stats.dart; change it here first.
//
// Privacy model (matches the App Store / Play declarations
// "Usage Data > Product Interaction, Not linked to you, Analytics"):
// - No identifier of any kind: no device ID, install ID, user ID or
//   advertising ID. The only thing stored on the device is the install date.
// - The app sends one small batch per day with tallies such as
//   {"screen.map": 3, "onboarding.done": 1} and whether it was opened that
//   day. The server keeps aggregates only.
// - The user can switch it off in Settings (UsageStats.setEnabled(false));
//   unsent tallies are deleted at once.
//
// Retention without an ID: the server adds 1 to (install day, days since
// install) for each day the app is opened, so D1/D7/D14/D28 come from
// counters alone.
//
// Engagement, still without identifiers (all are plain daily counters):
// - session.start: a cold start, or a return after 30+ minutes away;
// - time.sec: seconds in the foreground; visit.m0_1 / m1_5 / m5_20 / m20p:
//   length of each foreground stretch;
// - nav.<from>.<to>: screen-to-screen transitions (a "transition map");
// - content.<type>.<id>: which catalog items are opened (trail, word list,
//   dataset...). Ids must come from the app's own catalog, never from text
//   the user typed.
//
// Optional extra sinks (UsageSink) let an app forward the same calls to
// another backend later, e.g. Firebase Analytics after explicit consent.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

/// Another destination for the same events (e.g. Firebase Analytics).
/// A sink is responsible for its own consent handling.
abstract class UsageSink {
  void event(String name, int count);
  void screen(String name);
  Future<void> setEnabled(bool enabled);
}

class UsageStats with WidgetsBindingObserver {
  UsageStats._();
  static final UsageStats _i = UsageStats._();

  static const _endpoint = 'https://usage.azenha.ai/v1/batch';
  static const _maxAgeDays = 45;
  static const _chunkDays = 14;
  static final _nameRe = RegExp(r'^[a-z0-9_]+(\.[a-z0-9_]+){0,3}$');

  String? _app;
  String _version = '0';
  String _platform = 'unknown';
  bool _enabled = true;
  String? _installDay; // null = installed before analytics existed
  String? _activeSentDay; // last day whose "opened" flag reached the server
  final Map<String, _DayTally> _pending = {};
  final List<UsageSink> _sinks = [];
  late Future<String?> Function() _read;
  late Future<void> Function(String) _write;
  http.Client _client = http.Client();
  DateTime Function() _now = DateTime.now;
  Future<void>? _flushing;
  String? _lastScreen;
  DateTime? _fgStart; // foreground since
  DateTime? _bgAt; // went to background at
  static const _sessionGap = Duration(minutes: 30);
  Timer? _saveTimer;

  /// Call once after WidgetsFlutterBinding.ensureInitialized().
  ///
  /// [read]/[write] persist one small JSON string (SharedPreferences, a file,
  /// secure storage - whatever the app already uses).
  /// [existingUser]: true when this device already used the app before this
  /// build (any saved settings exist). Such installs count as active users but
  /// never enter the retention cohorts, because their real install date is
  /// unknown.
  static Future<void> init({
    required String app,
    required String version,
    required Future<String?> Function() read,
    required Future<void> Function(String) write,
    bool existingUser = false,
    List<UsageSink> sinks = const [],
    @visibleForTesting http.Client? client,
    @visibleForTesting DateTime Function()? now,
    @visibleForTesting String? platform,
  }) async {
    final s = _i;
    s._app = app;
    s._version = version;
    s._read = read;
    s._write = write;
    s._sinks
      ..clear()
      ..addAll(sinks);
    if (client != null) s._client = client;
    if (now != null) s._now = now;
    s._platform = platform ?? _platformName();
    await s._load(existingUser);
    s._markOpened();
    s._bgAt = null;
    s._startSession();
    WidgetsBinding.instance.removeObserver(s);
    WidgetsBinding.instance.addObserver(s);
    unawaited(s._flush());
  }

  static bool get enabled => _i._enabled;

  /// Settings switch "Share anonymous usage statistics".
  static Future<void> setEnabled(bool on) async {
    final s = _i;
    s._enabled = on;
    if (!on) s._pending.clear();
    for (final k in s._sinks) {
      await k.setEnabled(on);
    }
    if (on) s._markOpened();
    await s._save();
  }

  /// Count a screen view, e.g. UsageStats.screen('map') -> "screen.map".
  /// Consecutive different screens also count as a transition "nav.a.b".
  static void screen(String name) {
    final s = _i;
    s._count('screen.$name', 1);
    final prev = s._lastScreen;
    if (prev != null && prev != name) s._count('nav.$prev.$name', 1);
    s._lastScreen = name;
    for (final k in _i._sinks) {
      k.screen(name);
    }
  }

  /// Count a feature use or step, e.g. 'feature.route_planned',
  /// 'onboarding.done'. Lowercase letters, digits, '_' and up to four
  /// dot-separated parts. Never put user content in a name.
  static void event(String name, [int count = 1]) {
    _i._count(name, count);
    for (final k in _i._sinks) {
      k.event(name, count);
    }
  }

  /// Count an opened catalog item, e.g. content('levada', 'pr1') ->
  /// "content.levada.pr1". [id] must be a catalog id, never user text; it is
  /// lowercased and anything outside [a-z0-9_] becomes '_'.
  static void content(String type, String id) {
    final clean = id.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    final max = 48 - 'content.'.length - type.length - 1;
    if (max < 1 || clean.isEmpty) return;
    event('content.$type.${clean.length > max ? clean.substring(0, max) : clean}');
  }

  /// Send what is pending now (also runs when the app goes to background).
  static Future<void> flush() => _i._flush();

  // ---------------------------------------------------------------------------

  static String _platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'unknown';
    }
  }

  String _day(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  String get _today => _day(_now());

  void _count(String name, int count) {
    if (!_enabled || _app == null || count <= 0) return;
    if (name.length > 48 || !_nameRe.hasMatch(name)) {
      debugPrint('UsageStats: ignored bad event name "$name"');
      return;
    }
    final t = _pending.putIfAbsent(_today, () => _DayTally());
    t.counts[name] = (t.counts[name] ?? 0) + count;
    _scheduleSave();
  }

  void _markOpened() {
    if (!_enabled || _app == null) return;
    final today = _today;
    if (_activeSentDay == today) return;
    _pending.putIfAbsent(today, () => _DayTally()).active = true;
    _scheduleSave();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markOpened();
      final away = _bgAt == null ? null : _now().difference(_bgAt!);
      if (away != null && away >= _sessionGap) {
        _lastScreen = null;
        _startSession();
      } else {
        _fgStart ??= _now();
      }
      unawaited(_flush());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _endForeground();
      unawaited(_flush());
    }
  }

  void _startSession() {
    _count('session.start', 1);
    _fgStart = _now();
  }

  // Close a foreground stretch: add its seconds and its length bucket.
  void _endForeground() {
    final start = _fgStart;
    if (start == null) return;
    _fgStart = null;
    _bgAt = _now();
    final sec = _bgAt!.difference(start).inSeconds;
    if (sec <= 0) return;
    _count('time.sec', sec.clamp(1, 6 * 3600));
    final m = sec / 60;
    _count(
        m < 1
            ? 'visit.m0_1'
            : m < 5
                ? 'visit.m1_5'
                : m < 20
                    ? 'visit.m5_20'
                    : 'visit.m20p',
        1);
  }

  Future<void> _flush() {
    return _flushing ??= _send().whenComplete(() => _flushing = null);
  }

  Future<void> _send() async {
    if (!_enabled || _app == null) return;
    _dropOld();
    if (_pending.isEmpty) return;
    final days = _pending.keys.toList()..sort();
    for (var i = 0; i < days.length; i += _chunkDays) {
      final chunk = days.sublist(i, (i + _chunkDays).clamp(0, days.length));
      // Snapshot what is sent; events counted meanwhile stay pending.
      final sent = {for (final d in chunk) d: _pending[d]!.copy()};
      final body = jsonEncode({
        'app': _app,
        'platform': _platform,
        'version': _version,
        'install_day': _installDay,
        'days': [
          for (final e in sent.entries)
            {'day': e.key, 'active': e.value.active, 'counts': e.value.counts},
        ],
      });
      int status;
      try {
        final r = await _client
            .post(Uri.parse(_endpoint),
                headers: {'content-type': 'application/json'}, body: body)
            .timeout(const Duration(seconds: 10));
        status = r.statusCode;
      } catch (_) {
        status = 0; // offline: keep everything for later
      }
      if (status == 0 || status == 429 || status >= 500) break;
      // 2xx: delivered. 4xx: the server will never accept it; drop it.
      for (final e in sent.entries) {
        final cur = _pending[e.key];
        if (cur == null) continue;
        cur.subtract(e.value);
        if (e.value.active && status < 300) {
          _activeSentDay = (_activeSentDay == null ||
                  e.key.compareTo(_activeSentDay!) > 0)
              ? e.key
              : _activeSentDay;
        }
        if (cur.isEmpty) _pending.remove(e.key);
      }
    }
    await _save();
  }

  void _dropOld() {
    final cutoff = _day(_now().subtract(const Duration(days: _maxAgeDays)));
    _pending.removeWhere((d, _) => d.compareTo(cutoff) < 0);
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _save);
  }

  Future<void> _save() async {
    _saveTimer?.cancel();
    try {
      await _write(jsonEncode({
        'v': 1,
        'enabled': _enabled,
        'install_day': _installDay ?? 'legacy',
        'active_sent': _activeSentDay,
        'pending': {for (final e in _pending.entries) e.key: e.value.toJson()},
      }));
    } catch (_) {
      // Storage failure must never affect the app.
    }
  }

  Future<void> _load(bool existingUser) async {
    Map<String, dynamic>? j;
    try {
      final raw = await _read();
      if (raw != null && raw.isNotEmpty) {
        j = jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (_) {
      j = null;
    }
    _pending.clear();
    if (j == null) {
      _enabled = true;
      _installDay = existingUser ? null : _today;
      _activeSentDay = null;
      await _save();
      return;
    }
    _enabled = j['enabled'] != false;
    final inst = j['install_day'];
    _installDay = (inst is String && inst != 'legacy') ? inst : null;
    final a = j['active_sent'];
    _activeSentDay = a is String ? a : null;
    final p = j['pending'];
    if (p is Map) {
      p.forEach((k, v) {
        if (k is String && v is Map) _pending[k] = _DayTally.fromJson(v);
      });
    }
  }
}

class _DayTally {
  bool active = false;
  final Map<String, int> counts = {};

  bool get isEmpty => !active && counts.isEmpty;

  _DayTally copy() => _DayTally()
    ..active = active
    ..counts.addAll(counts);

  void subtract(_DayTally sent) {
    if (sent.active) active = false;
    sent.counts.forEach((k, v) {
      final left = (counts[k] ?? 0) - v;
      if (left > 0) {
        counts[k] = left;
      } else {
        counts.remove(k);
      }
    });
  }

  Map<String, dynamic> toJson() => {'a': active, 'c': counts};

  static _DayTally fromJson(Map v) {
    final t = _DayTally()..active = v['a'] == true;
    final c = v['c'];
    if (c is Map) {
      c.forEach((k, n) {
        if (k is String && n is num && n > 0) t.counts[k] = n.toInt();
      });
    }
    return t;
  }
}
