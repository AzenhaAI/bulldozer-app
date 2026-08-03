import 'package:flutter_test/flutter_test.dart';

import 'package:bulldozer_app/main.dart';

void main() {
  testWidgets('home renders brand and nav tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const BulldozerApp());
    // The Home stat boxes count up over 700 ms (TweenAnimationBuilder) — settle
    // the animation or its ticker trips the pending-timers invariant at teardown.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Stats'), findsWidgets);
    expect(find.text('Biz'), findsWidgets);
    expect(find.text('Polls'), findsWidgets);
    expect(find.text('Geo'), findsWidgets);
    expect(find.text('Edu'), findsWidgets);
  });
}
