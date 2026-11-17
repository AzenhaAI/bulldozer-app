// BullDozer's wiring of the shared anonymous usage counters (usage_stats.dart).
//
// usage_stats.dart is a verbatim copy of the canonical module in
// ~/Projects/_stores/usage/dart; everything app-specific lives here:
// start-up, install source, screen names, the activation flag, funnels and
// the content helpers. No experiments run (none is declared at init).
//
// Names only ever come from code or the catalog (screen names, dataset slugs,
// ISO codes). Nothing the reader types reaches an event name.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'flags.dart';
import 'usage_stats.dart';

const _kStore = 'usage_stats';
const _kFirstChart = 'usage_first_chart';

SharedPreferences? _prefs;

/// Starts the counters. Called from main() before runApp, so the first
/// screen is counted. Never throws: analytics must not stop the app.
Future<void> initUsage() async {
  try {
    final prefs = _prefs = await SharedPreferences.getInstance();
    // Any trace of an earlier version means the app ran before this build:
    // such installs count as active, but stay out of the retention cohorts.
    final firstRun = !prefs.containsKey(_kStore);
    final existing = firstRun && await _ranBefore(prefs);
    // Readers who already used the app have long since opened a chart; their
    // first chart after the update is not an activation.
    if (firstRun && existing) await prefs.setBool(_kFirstChart, true);
    // A test run passes --dart-define=USAGE_VERSION=0.0.0-test, so its rows
    // on the server can be found and deleted.
    var version = const String.fromEnvironment('USAGE_VERSION');
    if (version.isEmpty) {
      try {
        version = (await PackageInfo.fromPlatform()).version;
      } catch (_) {
        version = '0';
      }
    }
    await UsageStats.init(
      app: 'bulldozer',
      version: version,
      read: () async => prefs.getString(_kStore),
      write: (s) => prefs.setString(_kStore, s),
      existingUser: existing,
      installSource: _installSource,
      // Play pre-launch report robots (Firebase Test Lab) count nothing.
      testDevice: UsageStats.androidTestLab,
    );
    // Uncaught Dart errors as error.<type>.<file>_<line>; never the message.
    UsageStats.catchErrors();
  } catch (_) {
    // No storage, no counters; the app works the same.
  }
}

/// The channel that brought this install, asked once, on its first run.
/// Android: `utm_source` of the Play install referrer (`google-play` for an
/// organic install). Otherwise, or when that is empty: the `src` parameter of
/// the link the app was first opened with, e.g.
/// bulldozerstats://open/quiz?src=flyer_a6. Null when neither exists; the
/// module records that as `unknown`.
Future<String?> _installSource() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      final ref = (await PlayInstallReferrer.installReferrer).installReferrer;
      if (ref != null && ref.isNotEmpty) {
        final src = Uri.splitQueryString(ref)['utm_source'];
        if (src != null && src.isNotEmpty) return src;
      }
    } catch (_) {
      // Not installed from Play (sideloaded, emulator): fall through.
    }
  }
  return _linkSource(
      WidgetsBinding.instance.platformDispatcher.defaultRouteName);
}

/// The `src` query parameter of the route the app was started with: '/' for
/// a plain launch, '/quiz?src=x' (iOS) or the whole URL (Android cold start).
@visibleForTesting
String? linkSourceForTest(String route) => _linkSource(route);

/// A link that reached the Navigator after start-up. iOS hands a cold-start
/// link over late (defaultRouteName is always '/'), so [_installSource] never
/// sees its `src`. The module takes it only for a new install whose source is
/// still unknown and whose first batch has not gone out; it ignores every
/// later call, so the first link with a `src` wins.
void usageLinkRoute(String? route) {
  if (route == null) return;
  final src = _linkSource(route);
  if (src != null) unawaited(UsageStats.linkSource(src));
}

String? _linkSource(String route) {
  final src = Uri.tryParse(route)?.queryParameters['src'];
  return (src == null || src.isEmpty) ? null : src;
}

/// A step of a multi-step flow, counted once per install
/// (`funnel.<flow>.<step>`). Step conversion = step count / installs.
///
/// Flows:
/// - quiz: start, answer, done
/// - ask: brief (a country brief opened), consent (agreed to send questions
///   to the AI), sent, answer (an answer was shown)
/// - map: open (map maker), pick (an indicator chosen), share
/// - share: preview (share card opened), shared
void usageFunnel(String flow, String step) => UsageStats.funnel(flow, step);

/// A feature use, e.g. usageFeature('csv_export') -> "feature.csv_export".
void usageFeature(String name) => UsageStats.event('feature.$name');

/// A dataset (indicator) was opened; counts as the activation when it is the
/// install's first chart.
void usageDataset(String slug) {
  UsageStats.content('dataset', slug);
  usageFirstChart();
}

/// A dataset was picked for a chart (an axis, a map, a people chart).
void usageContentDataset(String slug) => UsageStats.content('dataset', slug);

/// A country was opened, by its catalog ISO alpha-3 code. Counted by alpha-2
/// where one exists (codes such as Somaliland's have none: kept as they are).
void usageCountry(String iso3) {
  final a2 = iso2FromIso3(iso3);
  UsageStats.content('country', a2.isNotEmpty ? a2 : iso3);
}

/// "activation.first_chart", once per install: the first dataset or chart.
void usageFirstChart() {
  final p = _prefs;
  if (p == null || p.getBool(_kFirstChart) == true) return;
  // While the reader has switched statistics off nothing is counted, and the
  // flag stays unset so the activation is not lost by a later switch-on.
  if (!UsageStats.enabled) return;
  p.setBool(_kFirstChart, true);
  UsageStats.event('activation.first_chart');
}

/// Did a version before 1.40 run on this device? 1.39 kept few settings in
/// SharedPreferences (AI consent, quiz count, offline download); most readers
/// have only its files: theme, favourites, reminders (support directory) and
/// the cached catalog (cache directory, written on every start).
Future<bool> _ranBefore(SharedPreferences prefs) async {
  if (prefs.getKeys().any((k) => k != _kStore)) return true;
  if (kIsWeb) return false;
  try {
    final support = (await getApplicationSupportDirectory()).path;
    for (final f in ['bd_theme.json', 'bd_favorites.json', 'bd_reminders.json']) {
      if (File('$support/$f').existsSync()) return true;
    }
    final cache = (await getApplicationCacheDirectory()).path;
    if (File('$cache/bd__data_catalog.json').existsSync()) return true;
  } catch (_) {}
  return false;
}

// --- Screens ----------------------------------------------------------------

String? _shown; // the screen counted last

/// Counts a screen view. [returning]: the screen came back into view (a page
/// above it closed, the tabs rebuilt for a theme switch); it is counted only
/// if another screen was counted in between, so closing a dialog-like page
/// that is not tracked does not count the same screen twice.
void usageScreen(String name, {bool returning = false}) {
  if (returning && _shown == name) return;
  _shown = name;
  UsageStats.screen(name);
}

/// Tells tracked screens when a page above them closes.
final usageRouteObserver = RouteObserver<PageRoute<dynamic>>();

/// Mix into a page's State to count it: on open, and again when the reader
/// comes back to it from a page above. That return is what makes the
/// transition map (`nav.<from>.<to>`) follow the real path through the app.
mixin UsageScreen<T extends StatefulWidget> on State<T> implements RouteAware {
  /// The screen's name: lowercase letters, digits and '_'.
  String get usageScreenName;

  /// True for a screen that is rebuilt in place (the tabs, on a theme
  /// switch): its new State does not count the same screen again.
  bool get usageQuietRebuild => false;

  PageRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    usageScreen(usageScreenName, returning: usageQuietRebuild);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = ModalRoute.of(context);
    if (r is PageRoute<dynamic> && r != _route) {
      if (_route != null) usageRouteObserver.unsubscribe(this);
      _route = r;
      usageRouteObserver.subscribe(this, r);
    }
  }

  @override
  void dispose() {
    usageRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => usageScreen(usageScreenName, returning: true);

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {}
}
