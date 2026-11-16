// BullDozer's screen wiring (lib/usage.dart): a page counts on open and again
// when the reader returns to it, so transitions follow the real path.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bulldozer_app/usage.dart';
import 'package:bulldozer_app/usage_stats.dart';

class _Page extends StatefulWidget {
  final String name;
  final Widget? next;
  const _Page(this.name, [this.next]);

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> with UsageScreen<_Page> {
  @override
  String get usageScreenName => widget.name;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: TextButton(
          onPressed: widget.next == null
              ? null
              : () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => widget.next!)),
          child: Text(widget.name),
        ),
      );
}

void main() {
  testWidgets('opening a page and coming back counts screens and transitions',
      (tester) async {
    String? stored;
    final sent = <Map<String, dynamic>>[];
    await UsageStats.init(
      app: 'bulldozer',
      version: '0.0.0-test',
      read: () async => stored,
      write: (s) async => stored = s,
      platform: 'ios',
      client: MockClient((req) async {
        sent.add(jsonDecode(req.body) as Map<String, dynamic>);
        return http.Response('', 204);
      }),
    );
    await tester.runAsync(UsageStats.flush);
    sent.clear();

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [usageRouteObserver],
      home: const _Page('countries', _Page('country', _Page('dataset'))),
    ));
    await tester.tap(find.text('countries'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('country'));
    await tester.pumpAndSettle();
    // Back twice: dataset -> country -> countries.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await tester.runAsync(UsageStats.flush);
    final counts = <String, int>{};
    for (final b in sent) {
      for (final d in b['days'] as List) {
        (d['counts'] as Map).forEach((k, v) => counts[k as String] =
            (counts[k] ?? 0) + (v as int));
      }
    }
    expect(counts['screen.countries'], 2);
    expect(counts['screen.country'], 2);
    expect(counts['screen.dataset'], 1);
    expect(counts['nav.countries.country'], 1);
    expect(counts['nav.country.dataset'], 1);
    expect(counts['nav.dataset.country'], 1);
    expect(counts['nav.country.countries'], 1);
  });
}
