// ignore_for_file: avoid_print, avoid_relative_lib_imports
// dart run tools/check_chart_rules.dart — checks lib/widgets/chart_rules.dart
// against SciPy / pymannkendall answers in test/trend_vectors.json (the same
// file the website's test uses). Plain Dart, no Flutter needed.
import 'dart:convert';
import 'dart:io';
import '../lib/widgets/chart_rules.dart';

void main() {
  final cases = (jsonDecode(File('test/trend_vectors.json').readAsStringSync())['cases'] as List).cast<Map>();
  var bad = 0;
  bool near(double a, double b, double tol) => (a - b).abs() <= tol * [1.0, b.abs()].reduce((x, y) => x > y ? x : y);
  List<double> d(List l) => [for (final v in l) (v as num).toDouble()];
  for (final c in cases) {
    final xs = d(c['x']), ys = d(c['y']);
    final ts = theilSen(xs, ys), m = mannKendall(ys);
    final ok = near(ts.slope, (c['slope'] as num).toDouble(), 1e-9) &&
        near(ts.intercept, (c['intercept'] as num).toDouble(), 1e-9) &&
        m.s == (c['s'] as num).toDouble() &&
        near(m.z, (c['z'] as num).toDouble(), 1e-9) &&
        (m.p - (c['p'] as num).toDouble()).abs() < 1e-6;
    if (!ok) {
      bad++;
      print('✗ ${c['name']} slope ${ts.slope}/${c['slope']} s ${m.s}/${c['s']} p ${m.p}/${c['p']}');
    }
  }
  void check(bool cond, String msg) { if (!cond) { bad++; print('✗ $msg'); } }
  check(isFlat([0, 0, 0, 0]) && !isFlat([1, 1.2]) && isFlat([1.04, 0.96]), 'isFlat');
  check(yDomain([0, 0, 0]).$1 == 0 && yDomain([0, 0, 0]).$2 > 0, 'flat zero domain never negative');
  check(yDomain([65, 76], area: true).$1 == 0, 'area starts at 0');
  check(yDomain([-3, 2], nonNegative: false).$1 < -3, 'negative allowed when data has negatives');
  check(periodYear('2021–2023') == 2022 && periodYear('2016') == 2016, 'periodYear');
  print(bad == 0 ? '✓ all ${cases.length + 5} checks pass' : '$bad failed');
  exit(bad == 0 ? 0 : 1);
}
