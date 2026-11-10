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
  check(yDomain([0, 0, 0]).$1 < 0 && yDomain([0, 0, 0]).$2 > 0, 'flat series still gets a range');
  check(yDomain([65, 76]).$1 > 64 && yDomain([65, 76]).$2 < 77, 'axis zooms to the data');
  check(niceTicks(-10.7, 10.9, count: 5).join(',') == '-10.0,-5.0,0.0,5.0,10.0', 'round ticks with 0: ${niceTicks(-10.7, 10.9, count: 5)}');
  check(!trendOf([for (var i = 0; i < 8; i++) (2016.0 + i, [70, 74, 77, 78, 77, 74, 70, 66][i].toDouble())])!.clear, 'no trend through a rise then fall');
  check(trendOf([for (var i = 0; i < 8; i++) (2016.0 + i, 50 + i * 1.5)])!.clear, 'steady rise is a trend');
  check(periodYear('2021–2023') == 2022 && periodYear('2016') == 2016, 'periodYear');
  final lw = (jsonDecode(File('test/lowess_vectors.json').readAsStringSync())['cases'] as List).cast<Map>();
  for (final c in lw) {
    final sm = lowess(d(c['x']), d(c['y']), frac: 0.3);
    final ref = d(c['smooth']);
    var worst = 0.0;
    for (var i = 0; i < sm.length; i++) { worst = [worst, (sm[i] - ref[i]).abs()].reduce((a, b) => a > b ? a : b); }
    if (!(worst < 1e-8)) { bad++; print('✗ lowess ${c['name']} $worst'); }
  }
  print(bad == 0 ? '✓ all ${cases.length} trend cases, ${lw.length} lowess series and 6 rule checks pass' : '$bad failed');
  exit(bad == 0 ? 0 : 1);
}
