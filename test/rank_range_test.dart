import 'package:flutter_test/flutter_test.dart';
import 'package:bulldozer_app/api.dart';

void main() {
  test('observations expose a published interval', () {
    final o = Observation.fromJson({'entity': 'X', 'period': '2023', 'value': 67, 'iso': 'PRT', 'lo': 63, 'hi': 72});
    expect(o.interval, (63.0, 72.0));
    final s = Observation.fromJson({'entity': 'Y', 'period': '2023', 'value': 50, 'iso': 'ESP', 'moe': 3.1});
    expect(s.interval, isNull);
    expect(s.moe, 3.1);
  });
}
