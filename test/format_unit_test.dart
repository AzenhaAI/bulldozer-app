import 'package:flutter_test/flutter_test.dart';
import 'package:bulldozer_app/api.dart';

void main() {
  test('values carry a short unit', () {
    expect(formatWithUnit(1450.9, 'million'), '1.5B');
    expect(formatWithUnit(10.7, 'million'), '10.7M');
    expect(formatWithUnit(3.1, '%'), '3.1%');
    expect(formatWithUnit(52800, 'intl\$'), '\$52.8k');
    expect(formatWithUnit(4.2, '% of GDP'), '4.2% of GDP');
    expect(formatWithUnit(73.2, 'years'), '73.2 yrs');
    expect(formatWithUnit(0.81, 'index 0–1'), '0.81');
    expect(formatWithUnit(12, 'per 100k'), '12.0 per 100k');
  });
}
