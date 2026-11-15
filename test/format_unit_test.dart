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
    expect(formatWithUnit(39, '0–100'), '39.0');
    expect(formatWithUnit(9, 'count'), '9');
    expect(formatWithUnit(0.001, '% of world'), '0.001% of world');
    expect(formatWithUnit(19906, '% YoY'), '19,906%');
    expect(formatWithUnit(25.2, '2017 intl\$/hr'), '\$25.2/hr');
    expect(formatWithUnit(26, 'bn'), '\$26.0B');
    expect(formatWithUnit(18.7, r'$ per day (PPP)'), '\$18.7 a day (PPP)');
    expect(formatValue(0.002), '0.002');
  });
}
