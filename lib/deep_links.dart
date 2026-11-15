import 'package:flutter/material.dart';

import 'catalog_store.dart';
import 'charts_page.dart' show DatasetPage;
import 'economy_week_page.dart';
import 'quiz_page.dart';
import 'stats_basics_page.dart';

/// Links into the app, for App Store in-app events, Google Play promotional
/// content and anything else that wants to open one screen:
///
/// ```text
///   bulldozerstats://open/economy          Economy this week
///   bulldozerstats://open/biz              a tab: home ask stats biz polls geo edu
///   bulldozerstats://open/dataset/<slug>   one indicator, e.g. imf-gdp-growth
///   bulldozerstats://open/quiz             the country quiz
///   bulldozerstats://open/basics           Statistics basics
/// ```
///
/// Flutter's deep linking (FlutterDeepLinkingEnabled / flutter_deeplinking_enabled)
/// hands the URL's path to the Navigator as a route name ("/economy"); the
/// "open" host is not part of it. A leading "open" segment is skipped anyway,
/// so a link written as bulldozerstats:///open/economy still lands.
/// Apple refused to review an in-app event without a deep link, and 1.39.0
/// had none (15 Nov 2026).
const kTabLinks = {'home': 0, 'ask': 1, 'stats': 2, 'biz': 3, 'polls': 4, 'geo': 5, 'edu': 6};

/// A tab asked for by a link; the shell listens and switches.
final shellTabRequest = ValueNotifier<int?>(null);

Route<dynamic> deepLinkRoute(RouteSettings s) {
  var seg = Uri.tryParse(s.name ?? '')?.pathSegments.where((p) => p.isNotEmpty).toList() ?? const <String>[];
  if (seg.isNotEmpty && seg.first == 'open') seg = seg.sublist(1);
  final page = seg.isEmpty ? '' : seg.first.toLowerCase();

  Route<dynamic> screen(Widget w) => MaterialPageRoute(settings: s, builder: (_) => w);

  if (kTabLinks[page] case final i?) return _tabSwitch(i);
  switch (page) {
    case 'economy':
      return screen(const EconomyWeekPage());
    case 'quiz':
      return screen(const QuizPage());
    case 'basics':
      return screen(const StatsBasicsPage());
    case 'dataset':
      if (seg.length > 1) {
        final hit = catalog.where((e) => e.slug == seg[1]);
        if (hit.isNotEmpty) return screen(DatasetPage(entry: hit.first));
      }
  }
  // Unknown or stale link: stay where the reader is. The Navigator has to
  // push something for a named route, so push a route that closes itself.
  return _closing(() {});
}

/// Switch the tab and close everything above the tabs, so the switch is seen.
Route<dynamic> _tabSwitch(int i) => _closing(() => shellTabRequest.value = i, toRoot: true);

Route<dynamic> _closing(VoidCallback then, {bool toRoot = false}) => PageRouteBuilder(
    opaque: false,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (ctx, _, _) {
      // After the frame: the route may not pop itself while it is being built.
      // It removes itself, not whatever is on top: a cold start from
      // /dataset/<slug> stacks '/', '/dataset' and '/dataset/<slug>', and a
      // pop from the empty middle route closed the indicator above it.
      final self = ModalRoute.of(ctx);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        then();
        final nav = Navigator.of(ctx);
        if (toRoot) {
          nav.popUntil((r) => r.isFirst);
        } else if (self != null && self.isActive) {
          nav.removeRoute(self);
        }
      });
      return const SizedBox.shrink();
    });
