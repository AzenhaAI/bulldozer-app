import 'package:bulldozer_app/catalog_store.dart';
import 'package:bulldozer_app/deep_links.dart';
import 'package:bulldozer_app/stats_basics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// bulldozerstats://open/<screen> arrives as a route name; see deep_links.dart.
Widget app(String route) => MaterialApp(
      home: const Text('tabs'),
      onGenerateRoute: deepLinkRoute,
      initialRoute: route,
    );

void main() {
  testWidgets('a screen link opens over the tabs, Back returns to them', (t) async {
    await t.pumpWidget(app('/basics'));
    await t.pumpAndSettle();
    expect(find.byType(StatsBasicsPage), findsOneWidget);
    t.state<NavigatorState>(find.byType(Navigator)).pop();
    await t.pumpAndSettle();
    expect(find.text('tabs'), findsOneWidget);
  });

  testWidgets('a leading "open" segment is skipped', (t) async {
    await t.pumpWidget(app('/open/basics'));
    await t.pumpAndSettle();
    expect(find.byType(StatsBasicsPage), findsOneWidget);
  });

  testWidgets('a cold start from a nested link keeps the linked screen', (t) async {
    // '/open/basics' stacks '/', '/open' and '/open/basics'; the empty middle
    // route must not take the screen above it with it.
    await t.pumpWidget(app('/open/basics'));
    await t.pumpAndSettle();
    expect(find.byType(StatsBasicsPage), findsOneWidget);
    t.state<NavigatorState>(find.byType(Navigator)).pop();
    await t.pumpAndSettle();
    expect(find.text('tabs'), findsOneWidget);
  });

  group('Android cold start: the whole URL is the only initial route', () {
    setUp(() => deepLinkShell = () => const Text('tabs'));
    tearDown(() => deepLinkShell = null);

    testWidgets('a screen link gets the tabs beneath it', (t) async {
      await t.pumpWidget(app('bulldozerstats://open/basics'));
      await t.pumpAndSettle();
      expect(find.byType(StatsBasicsPage), findsOneWidget);
      t.state<NavigatorState>(find.byType(Navigator)).pop();
      await t.pumpAndSettle();
      expect(find.text('tabs'), findsOneWidget);
    });

    testWidgets('a tab link shows the tabs, not a blank screen', (t) async {
      shellTabRequest.value = null;
      await t.pumpWidget(app('bulldozerstats://open/biz'));
      await t.pumpAndSettle();
      expect(shellTabRequest.value, 3);
      expect(find.text('tabs'), findsOneWidget);
      expect(t.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
    });

    testWidgets('an unknown link leaves the tabs', (t) async {
      await t.pumpWidget(app('bulldozerstats://open/nope'));
      await t.pumpAndSettle();
      expect(find.text('tabs'), findsOneWidget);
      expect(t.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
    });
  });

  testWidgets('a tab link asks the shell for the tab and leaves the tabs showing', (t) async {
    shellTabRequest.value = null;
    await t.pumpWidget(app('/biz'));
    await t.pumpAndSettle();
    expect(shellTabRequest.value, 3);
    expect(find.text('tabs'), findsOneWidget);
    expect(t.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
  });

  testWidgets('an unknown link closes itself', (t) async {
    await t.pumpWidget(app('/no-such-screen'));
    await t.pumpAndSettle();
    expect(find.text('tabs'), findsOneWidget);
    expect(t.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
  });

  test('dataset links resolve every slug in the baked catalog', () {
    expect(catalog, isNotEmpty);
    for (final e in catalog.take(50)) {
      final r = deepLinkRoute(RouteSettings(name: '/dataset/${e.slug}'));
      expect(r, isA<MaterialPageRoute>(), reason: e.slug);
    }
    expect(deepLinkRoute(const RouteSettings(name: '/economy')), isA<MaterialPageRoute>());
    expect(deepLinkRoute(const RouteSettings(name: '/dataset/nope')), isNot(isA<MaterialPageRoute>()));
  });
}
