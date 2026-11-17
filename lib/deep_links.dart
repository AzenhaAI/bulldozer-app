import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'catalog_store.dart';
import 'charts_page.dart' show DatasetPage;
import 'economy_week_page.dart';
import 'quiz_page.dart';
import 'stats_basics_page.dart';
import 'usage.dart';

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
/// Since 1.40 the site's own pages open here too, when the app is installed
/// (Universal Links on iOS, App Links on Android; the azenha.ai/.well-known
/// files list the paths):
///
/// ```text
///   https://azenha.ai/bulldozer/dataset/<slug>/   the same indicator
///   https://azenha.ai/bulldozer/economy/          Economy this week
/// ```
///
/// Their path starts with "bulldozer", which is skipped like "open". An
/// indicator missing from the catalog this build started with is looked up in
/// the site's fresh catalog first (an indicator added since); one the app does
/// not carry at all (the RLMS and Bank of Russia series) opens on the site in
/// an in-app view. Android only routes the prefixes of the app's own sources
/// here (AndroidManifest.xml), so those pages normally stay in the browser.
///
/// Flutter's deep linking (FlutterDeepLinkingEnabled / flutter_deeplinking_enabled)
/// hands the URL's path to the Navigator as a route name ("/economy"); the
/// "open" host is not part of it — except on an Android cold start, see
/// [deepLinkShell]. A leading "open" segment is skipped anyway.
/// Apple refused to review an in-app event without a deep link, and 1.39.0
/// had none (15 Nov 2026).
const kTabLinks = {'home': 0, 'ask': 1, 'stats': 2, 'biz': 3, 'polls': 4, 'geo': 5, 'edu': 6};

/// A tab asked for by a link; the shell listens and switches.
final shellTabRequest = ValueNotifier<int?>(null);

/// Builds the tabs, set by the app. On an Android cold start Flutter hands the
/// whole URL ("bulldozerstats://open/economy") over as the only initial route;
/// a name without a leading '/' does not stack `home` under it, so the linked
/// screen opened with nothing beneath it, a tab link left a blank screen and
/// Back closed the app (review, 15 Nov 2026). Such a route brings the tabs
/// itself and then opens the link's path over them, as iOS and warm starts do.
Widget Function()? deepLinkShell;

Route<dynamic> deepLinkRoute(RouteSettings s) {
  usageLinkRoute(s.name);
  final uri = Uri.tryParse(s.name ?? '');
  final shell = deepLinkShell;
  if (uri != null && uri.hasScheme && shell != null) {
    final path = uri.pathSegments.where((p) => p.isNotEmpty).join('/');
    var opened = false;
    return MaterialPageRoute(
        settings: const RouteSettings(name: '/'),
        builder: (ctx) {
          if (!opened && path.isNotEmpty) {
            opened = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ctx.mounted) Navigator.of(ctx).pushNamed('/$path');
            });
          }
          return shell();
        });
  }
  var seg = Uri.tryParse(s.name ?? '')?.pathSegments.where((p) => p.isNotEmpty).toList() ?? const <String>[];
  if (seg.isNotEmpty && seg.first == 'open') seg = seg.sublist(1);
  final fromSite = seg.isNotEmpty && seg.first == 'bulldozer';
  if (fromSite) seg = seg.sublist(1);
  final page = seg.isEmpty ? '' : seg.first.toLowerCase();

  Route<dynamic> screen(Widget w) => MaterialPageRoute(settings: s, builder: (_) => w);

  if (kTabLinks[page] case final i?) return _tabSwitch(i);
  switch (page) {
    case 'economy':
      return screen(const EconomyWeekPage());
    case 'quiz':
      return screen(const QuizScreen());
    case 'basics':
      return screen(const StatsBasicsPage());
    case 'dataset':
      if (seg.length > 1) {
        final hit = catalog.where((e) => e.slug == seg[1]);
        if (hit.isNotEmpty) return screen(DatasetPage(entry: hit.first));
        if (fromSite) return _siteDataset(seg[1]);
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

/// A site indicator not in the catalog this build started with: refresh the
/// catalog (a cold start still has the baked one), then open it, or show the
/// site's page if the app does not carry it.
Route<dynamic> _siteDataset(String slug) {
  var started = false;
  return PageRouteBuilder(
      opaque: false,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (ctx, _, _) {
        final self = ModalRoute.of(ctx);
        if (!started) {
          started = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await loadCatalog().timeout(const Duration(seconds: 4));
            } catch (_) {}
            if (!ctx.mounted || self == null || !self.isActive) return;
            final nav = Navigator.of(ctx);
            final hit = catalog.where((e) => e.slug == slug);
            if (hit.isNotEmpty) {
              nav.replace(
                  oldRoute: self,
                  newRoute: MaterialPageRoute(builder: (_) => DatasetPage(entry: hit.first)));
            } else {
              nav.removeRoute(self);
              _openOnSite('dataset/$slug/');
            }
          });
        }
        return const SizedBox.shrink();
      });
}

/// A site page the app has no screen for, shown inside the app. Not handed to
/// a browser: the link is the app's own (Universal Links / App Links), so the
/// system would bring it straight back here. iOS shows it in an
/// SFSafariViewController, which never does; on Android a Custom Tab is an
/// ordinary view intent that would, so it opens in the in-app web view.
void _openOnSite(String path) {
  final uri = Uri.https('azenha.ai', '/bulldozer/$path');
  final mode = defaultTargetPlatform == TargetPlatform.android
      ? LaunchMode.inAppWebView
      : LaunchMode.inAppBrowserView;
  launchUrl(uri, mode: mode).catchError((_) => false);
}
