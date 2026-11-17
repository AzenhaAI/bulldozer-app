// Anonymous daily usage counters for Azenha AI apps.
//
// Canonical copy: ~/Projects/_stores/usage/dart/usage_stats.dart. Each app
// keeps an identical copy in lib/usage_stats.dart; change it here first.
//
// Privacy model (matches the App Store / Play declarations
// "Usage Data > Product Interaction, Not linked to you, Analytics"):
// - No identifier of any kind: no device ID, install ID, user ID or
//   advertising ID. The only thing stored on the device is the install date.
// - Whenever the app is opened or left, it sends the day's unsent tallies
//   such as {"screen.map": 3, "onboarding.done": 1} and whether it was opened
//   that day (nothing is sent when there is nothing new). The server keeps
//   aggregates only.
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
// What the big trackers (AppsFlyer, Adjust, AppMetrica, Yandex Metrica) are
// known for, done without identifiers:
// - install source (attribution): `installSource` at init, e.g. the Play
//   install referrer's utm_source; a deep-link `src` that arrives after start
//   (iOS delivers links late) goes through linkSource(); retention is split by it;
// - A/B experiments: `experiments` at init; each install gets one arm,
//   stored locally; retention is split by arm; read it with variant();
// - funnels: funnel('onboarding', 'step') counts each step once per install;
// - unique actives: active.week / active.month count each install once per
//   calendar week / month (WAU, MAU); DAU is the server's daily "opened";
// - audience: once a day, UI language, phone/tablet, dark/light, large text;
// - errors: catchErrors() counts uncaught Dart errors by type and code
//   location in the app (never the message text) -> errors per version.
//
// Optional extra sinks (UsageSink) let an app forward the same calls to
// another backend later, e.g. Firebase Analytics after explicit consent.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
  final Map<String, String> _tags = {}; // cohort segments: source, exp_*
  final Set<String> _funnelDone = {};
  String? _audienceDay;
  String? _weekMarked; // ISO week (its Monday) already counted in active.week
  String? _monthMarked; // calendar month already counted in active.month
  static final _cleanRe = RegExp(r'[^a-z0-9_]');

  static String _clean(String s, int max) {
    final c = s.toLowerCase().replaceAll(_cleanRe, '_');
    return c.length > max ? c.substring(0, max) : c;
  }
  Timer? _saveTimer;
  bool _tagsSent = false; // cohort tags already left the device: frozen now
  Timer? _holdTimer; // first run: wait briefly for a late deep link
  static const _firstRunHold = Duration(seconds: 5);

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
    Future<String?> Function()? installSource,
    Map<String, List<String>> experiments = const {},
    List<UsageSink> sinks = const [],
    @visibleForTesting http.Client? client,
    @visibleForTesting DateTime Function()? now,
    @visibleForTesting String? platform,
  }) async {
    final s = _i;
    s._holdTimer?.cancel();
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
    final firstRun = await s._load(existingUser);
    final newInstall = firstRun && !existingUser;
    if (newInstall) {
      await s._assignCohortTags(installSource, experiments);
    }
    s._markOpened();
    s._bgAt = null;
    s._startSession();
    WidgetsBinding.instance.removeObserver(s);
    WidgetsBinding.instance.addObserver(s);
    if (newInstall && s._tags['source'] == 'unknown') {
      // On iOS a launch link reaches the app only after start-up
      // (pushRouteInformation), so give linkSource() a moment before the
      // first batch fixes the cohort tags.
      s._holdTimer = Timer(_firstRunHold, () => unawaited(s._flush()));
    } else {
      unawaited(s._flush());
    }
  }

  static bool get enabled => _i._enabled;

  /// Install source from a deep link that arrived after init, e.g. the `src`
  /// query of the first route seen in onGenerateRoute or a link listener.
  /// Applies only to a new install whose source is still 'unknown' and whose
  /// cohort tags have not been sent yet; ignored otherwise, so a cohort never
  /// changes segment after its first batch.
  static Future<void> linkSource(String? src) async {
    final s = _i;
    if (s._app == null || s._installDay == null || s._tagsSent) return;
    if (s._tags['source'] != 'unknown') return;
    final clean = _clean(src ?? '', 32);
    if (clean.isEmpty) return;
    s._tags['source'] = clean;
    await s._save();
  }

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

  /// The arm this install got for an experiment declared at init, or null
  /// (installs that predate the experiment, or analytics switched off).
  static String? variant(String experiment) => _i._tags['exp_${_clean(experiment, 20)}'];

  /// Count a funnel step once per install, e.g. funnel('onboarding', 'language_picked').
  static void funnel(String name, String step) {
    final s = _i;
    if (!s._enabled || s._app == null) return;
    final key = 'funnel.${_clean(name, 16)}.${_clean(step, 24)}';
    if (!s._funnelDone.add(key)) return;
    s._count(key, 1);
  }

  /// Count uncaught Dart errors as `error.<type>.<file>_<line>` (location in the
  /// app's own code; the message text is never sent). Chains existing handlers.
  static void catchErrors() {
    final prevFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      _i._countError(details.exception, details.stack);
      if (prevFlutter != null) {
        prevFlutter(details);
      } else {
        FlutterError.presentError(details);
      }
    };
    final dispatcher = PlatformDispatcher.instance;
    final prevAsync = dispatcher.onError;
    dispatcher.onError = (error, stack) {
      _i._countError(error, stack);
      return prevAsync?.call(error, stack) ?? false;
    };
  }

  /// Send what is pending now (also runs when the app goes to background).
  static Future<void> flush() {
    _i._holdTimer?.cancel();
    return _i._flush();
  }

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
    _countAudience(today);
    _countPeriods();
    if (_activeSentDay == today) return;
    _pending.putIfAbsent(today, () => _DayTally()).active = true;
    _scheduleSave();
  }

  // Unique actives without an ID: each install adds 1 the first time it is
  // opened in a calendar week (Monday-Sunday) and a calendar month, so the
  // sums of active.week / active.month are WAU / MAU.
  void _countPeriods() {
    final now = _now();
    final d = DateTime(now.year, now.month, now.day);
    final week = _day(d.subtract(Duration(days: d.weekday - 1)));
    final month = _day(d).substring(0, 7);
    if (_weekMarked != week) {
      _weekMarked = week;
      _count('active.week', 1);
    }
    if (_monthMarked != month) {
      _monthMarked = month;
      _count('active.month', 1);
    }
  }

  // Once a day: coarse device settings, no identifiers, no location.
  void _countAudience(String today) {
    if (_audienceDay == today) return;
    _audienceDay = today;
    try {
      final d = PlatformDispatcher.instance;
      final lang = _clean(d.locale.languageCode, 8);
      if (lang.isNotEmpty) _count('aud.lang.$lang', 1);
      if (d.views.isNotEmpty) {
        final v = d.views.first;
        final side = v.physicalSize.shortestSide / v.devicePixelRatio;
        if (side > 0) _count(side >= 600 ? 'aud.form.tablet' : 'aud.form.phone', 1);
      }
      _count(d.platformBrightness.name == 'dark' ? 'aud.theme.dark' : 'aud.theme.light', 1);
      _count(d.textScaleFactor >= 1.3 ? 'aud.text.large' : 'aud.text.normal', 1);
    } catch (_) {
      // Audience is optional.
    }
  }

  void _countError(Object error, StackTrace? stack) {
    try {
      final type = _clean(error.runtimeType.toString(), 16);
      var where = 'unknown';
      final pkg = 'package:';
      for (final line in (stack?.toString() ?? '').split('\n')) {
        final i = line.indexOf(pkg);
        if (i < 0 || line.contains('package:flutter/')) continue;
        // e.g. (package:bulldozer/map_page.dart:412:7)
        final m = RegExp(r'([A-Za-z0-9_]+)\.dart:(\d+)').firstMatch(line.substring(i));
        if (m != null) {
          where = '${_clean(m.group(1)!, 20)}_${m.group(2)}';
          break;
        }
      }
      final name = 'error.$type.$where';
      _count(name.length > 48 ? name.substring(0, 48) : name, 1);
    } catch (_) {
      // Never let error counting throw.
    }
  }

  Future<void> _assignCohortTags(
      Future<String?> Function()? installSource, Map<String, List<String>> experiments) async {
    if (installSource != null) {
      String? src;
      try {
        src = await installSource().timeout(const Duration(seconds: 3));
      } catch (_) {
        src = null;
      }
      final clean = _clean(src ?? '', 32);
      _tags['source'] = clean.isEmpty ? 'unknown' : clean;
    }
    final rnd = Random();
    for (final e in experiments.entries.take(3)) {
      if (e.value.isEmpty) continue;
      _tags['exp_${_clean(e.key, 20)}'] = _clean(e.value[rnd.nextInt(e.value.length)], 32);
    }
    await _save();
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
      _holdTimer?.cancel();
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
    if (_holdTimer?.isActive ?? false) return; // first-run hold, see init
    _dropOld();
    if (_pending.isEmpty) return;
    final days = _pending.keys.toList()..sort();
    for (var i = 0; i < days.length; i += _chunkDays) {
      // Switched off mid-send: pending was cleared, stop here.
      if (!_enabled) break;
      final chunk = days.sublist(i, (i + _chunkDays).clamp(0, days.length));
      // Snapshot what is sent; events counted meanwhile stay pending.
      final sent = {
        for (final d in chunk)
          if (_pending[d] != null) d: _pending[d]!.copy(),
      };
      if (sent.isEmpty) continue;
      final withTags = _installDay != null && _tags.isNotEmpty;
      if (withTags) _tagsSent = true;
      final body = jsonEncode({
        'app': _app,
        'platform': _platform,
        'version': _version,
        'install_day': _installDay,
        if (withTags) 'tags': _tags,
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
        'tags': _tags,
        'tags_sent': _tagsSent,
        'funnel': _funnelDone.toList(),
        'aud_day': _audienceDay,
        'week': _weekMarked,
        'month': _monthMarked,
        'pending': {for (final e in _pending.entries) e.key: e.value.toJson()},
      }));
    } catch (_) {
      // Storage failure must never affect the app.
    }
  }

  /// Returns true on the very first run with analytics.
  Future<bool> _load(bool existingUser) async {
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
    _tags.clear();
    _funnelDone.clear();
    _audienceDay = null;
    _weekMarked = null;
    _monthMarked = null;
    if (j == null) {
      _enabled = true;
      _installDay = existingUser ? null : _today;
      _activeSentDay = null;
      _tagsSent = false;
      await _save();
      return true;
    }
    _enabled = j['enabled'] != false;
    final inst = j['install_day'];
    _installDay = (inst is String && inst != 'legacy') ? inst : null;
    final a = j['active_sent'];
    _activeSentDay = a is String ? a : null;
    // Older saves have no flag; a delivered day means tags went out too.
    _tagsSent = j['tags_sent'] == true || _activeSentDay != null;
    final p = j['pending'];
    if (p is Map) {
      p.forEach((k, v) {
        if (k is String && v is Map) _pending[k] = _DayTally.fromJson(v);
      });
    }
    final t = j['tags'];
    if (t is Map) {
      t.forEach((k, v) {
        if (k is String && v is String) _tags[k] = v;
      });
    }
    final f = j['funnel'];
    if (f is List) _funnelDone.addAll(f.whereType<String>());
    final ad = j['aud_day'];
    _audienceDay = ad is String ? ad : null;
    final wk = j['week'];
    _weekMarked = wk is String ? wk : null;
    final mo = j['month'];
    _monthMarked = mo is String ? mo : null;
    return false;
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
