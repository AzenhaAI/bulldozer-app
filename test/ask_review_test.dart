import 'package:bulldozer_app/ask_review.dart';
import 'package:flutter_test/flutter_test.dart';

// When the system rating prompt may be asked for (ask_review.dart).
void main() {
  final now = DateTime(2026, 12, 1, 12);
  bool ok({int launches = 5, int seenDaysAgo = 10, int? askedDaysAgo}) => AskReview.eligible(
        now: now,
        launches: launches,
        firstSeen: now.subtract(Duration(days: seenDaysAgo)),
        lastAsked: askedDaysAgo == null ? null : now.subtract(Duration(days: askedDaysAgo)),
      );

  test('a returning reader is asked', () => expect(ok(), isTrue));
  test('never before the third launch', () => expect(ok(launches: 2), isFalse));
  test('never in the first three days', () => expect(ok(seenDaysAgo: 2), isFalse));
  test('three days and three launches are enough', () => expect(ok(launches: 3, seenDaysAgo: 3), isTrue));
  test('at most once in 90 days', () {
    expect(ok(askedDaysAgo: 89), isFalse);
    expect(ok(askedDaysAgo: 90), isTrue);
  });
  test('no first-run date, no prompt', () {
    expect(AskReview.eligible(now: now, launches: 9, firstSeen: null, lastAsked: null), isFalse);
  });
}
