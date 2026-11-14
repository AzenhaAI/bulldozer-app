import 'package:flutter_test/flutter_test.dart';
import 'package:bulldozer_app/widgets/trend_chart.dart' as tc;

void main() {
  test('tick labels keep the decimals the step needs', () {
    expect(tc.tickLabelForTest(0.8025, 0.0025), '0.8025');
    expect(tc.tickLabelForTest(0.805, 0.0025), '0.8050');
    expect(tc.tickLabelForTest(0.81, 0.005), '0.810');
    expect(tc.tickLabelForTest(0.9, 0.05), '0.90');
    expect(tc.tickLabelForTest(425, 25), '425');
  });
}
