import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bulldozer_app/main.dart';

const _tabs = ['Home', 'Stats', 'Biz', 'Polls', 'Geo', 'Edu'];

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const BulldozerApp());
  // The Home stat boxes count up over 700 ms (TweenAnimationBuilder) — settle
  // the animation or its ticker trips the pending-timers invariant at teardown.
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  // 320 is the narrowest iPhone still on iOS 15 (SE 1st gen); 390 is an
  // iPhone 14. The header overflowed at both until the wordmark was allowed
  // to shrink — and neither was covered while the suite pumped at the default
  // 800x600 test surface, which is tablet-wide.
  for (final (name, size) in const [
    ('an iPhone SE', Size(320, 568)),
    ('an iPhone 14', Size(390, 844)),
  ]) {
    testWidgets('home renders brand and nav tabs on $name', (tester) async {
      await _pumpAt(tester, size);
      expect(tester.takeException(), isNull);
      for (final label in _tabs) {
        expect(find.text(label), findsWidgets, reason: 'tab $label missing');
      }
    });
  }

  // The wide layout is a different tree, not the same one with more padding:
  // cards flow into columns, heroes gain a companion, the Biz entry cards share
  // a row. Every one of those is a Row inside a scroll view, where a careless
  // constraint asks for infinite height — which is exactly how the entry-card
  // row broke. These sizes are the real ones: 13" portrait and landscape.
  for (final (name, size) in const [
    ('an iPad in portrait', Size(1024, 1366)),
    ('an iPad in landscape', Size(1366, 1024)),
    ('an iPad mini, which stays single-column', Size(744, 1133)),
  ]) {
    testWidgets('shell lays out on $name', (tester) async {
      await _pumpAt(tester, size);
      expect(tester.takeException(), isNull);
      for (final label in _tabs) {
        expect(find.text(label), findsWidgets, reason: 'tab $label missing');
      }
    });
  }
}
