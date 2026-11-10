// Chart rules for time series — the same logic as the website's
// src/lib/trend.ts; both are checked against SciPy and pymannkendall answers
// (test/trend_vectors.json, `dart run tools/check_chart_rules.dart`).
//
//  1. Flat series: every value equal at display precision → no chart, the
//     number and "unchanged since <first year>".
//  2. Honest y-axis: a series with no negative reading anywhere never shows
//     negative ticks; an area fill starts at 0; a minimum span keeps rounding
//     noise from looking like a collapse.
//  3. x by time: "2013" and "2020" sit seven years apart, not one step.
//  4. Change in words: first → last, and the typical change per year.
//  5. Trend line: Theil–Sen slope (median of pairwise slopes — robust to one
//     odd year), drawn dashed over the observed years only, and only with at
//     least 6 readings and a consistent direction (Mann–Kendall p < 0.05).
//     Projections are left out of the fit.
//
// Pure Dart — no Flutter import — so it runs under plain `dart`.
import 'dart:math' as math;

/// Calendar position of a period label: "2021" → 2021, "2021–2023" → 2022.
double periodYear(String p) {
  final m = RegExp(r'\d{4}').allMatches(p).map((e) => double.parse(e.group(0)!)).toList();
  if (m.isEmpty) return double.nan;
  return m.length > 1 ? (m.first + m.last) / 2 : m.first;
}

/// A series is non-negative when no country, in any year, is below 0.
bool nonNegativeFrom(Iterable<double> allValues) => allValues.every((v) => !(v < 0));

/// True when every value rounds to the same number at [dp] decimals.
bool isFlat(List<double> values, {int dp = 1}) {
  if (values.length < 2) return true;
  final f = math.pow(10, dp);
  final r0 = (values.first * f).round();
  return values.every((v) => (v * f).round() == r0);
}

/// y-axis domain (min, max). See rule 2.
(double, double) yDomain(List<double> values,
    {bool nonNegative = true, bool area = false, double minSpanFrac = 0.1}) {
  var lo = values.reduce(math.min), hi = values.reduce(math.max);
  var minSpan = math.max(lo.abs(), hi.abs()) * minSpanFrac;
  if (minSpan == 0) minSpan = 1;
  if (hi - lo < minSpan) {
    final mid = (hi + lo) / 2;
    lo = mid - minSpan / 2;
    hi = mid + minSpan / 2;
  }
  final pad = (hi - lo) * 0.08;
  lo -= pad;
  hi += pad;
  if (area && lo > 0) lo = 0;
  if (nonNegative && lo < 0) lo = 0;
  return (lo, hi);
}

double _median(List<double> a) {
  final s = [...a]..sort();
  final n = s.length;
  return n.isOdd ? s[(n - 1) ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

/// Theil–Sen line: slope = median pairwise slope; intercept = median(y − slope·x).
({double slope, double intercept}) theilSen(List<double> xs, List<double> ys) {
  final slopes = <double>[];
  for (var i = 0; i < xs.length; i++) {
    for (var j = i + 1; j < xs.length; j++) {
      if (xs[j] != xs[i]) slopes.add((ys[j] - ys[i]) / (xs[j] - xs[i]));
    }
  }
  final slope = slopes.isEmpty ? 0.0 : _median(slopes);
  return (slope: slope, intercept: _median([for (var i = 0; i < ys.length; i++) ys[i] - slope * xs[i]]));
}

// Normal CDF via erf (Abramowitz & Stegun 7.1.26, error < 1.5e-7).
double _phi(double z) {
  final t = 1 / (1 + 0.3275911 * z.abs() / math.sqrt2);
  final e = 1 -
      (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) *
          t *
          math.exp(-(z * z) / 2);
  return z >= 0 ? (1 + e) / 2 : (1 - e) / 2;
}

/// Mann–Kendall test (two-sided, normal approximation, tie-corrected variance).
({double s, double z, double p}) mannKendall(List<double> ys) {
  final n = ys.length;
  var s = 0.0;
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      s += (ys[j] - ys[i]).sign;
    }
  }
  final ties = <double, int>{};
  for (final y in ys) {
    ties[y] = (ties[y] ?? 0) + 1;
  }
  var tieTerm = 0.0;
  for (final t in ties.values) {
    tieTerm += t * (t - 1) * (2 * t + 5);
  }
  final variance = (n * (n - 1) * (2 * n + 5) - tieTerm) / 18;
  final z = variance <= 0 || s == 0 ? 0.0 : (s > 0 ? s - 1 : s + 1) / math.sqrt(variance);
  return (s: s, z: z, p: 2 * (1 - _phi(z.abs())));
}

const kTrendMinPoints = 6;
const kTrendP = 0.05;

class Trend {
  final double slope, intercept, p, x0, x1;
  final int n;

  /// Enough readings and a consistent direction (Mann–Kendall p < 0.05).
  final bool clear;
  const Trend(this.slope, this.intercept, this.p, this.n, this.clear, this.x0, this.x1);
  double at(double x) => intercept + slope * x;
}

/// Points as (year, value); [projectedFrom] leaves projections out of the fit.
Trend? trendOf(List<(double, double)> points, {double? projectedFrom}) {
  final pts = points
      .where((p) => p.$1.isFinite && p.$2.isFinite && (projectedFrom == null || p.$1 < projectedFrom))
      .toList()
    ..sort((a, b) => a.$1.compareTo(b.$1));
  if (pts.length < 3) return null;
  final xs = [for (final p in pts) p.$1], ys = [for (final p in pts) p.$2];
  final ts = theilSen(xs, ys);
  final mk = mannKendall(ys);
  return Trend(ts.slope, ts.intercept, mk.p, pts.length,
      pts.length >= kTrendMinPoints && mk.p < kTrendP && ts.slope != 0, xs.first, xs.last);
}

String _fmt(double v, int dp) {
  final s = v.toStringAsFixed(dp);
  final parts = s.split('.');
  final int = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return parts.length > 1 ? '$int.${parts[1]}' : int;
}

/// One line under a chart: "−1.6 pp since 2013 · trend −0.2 pp a year".
/// [mode] 'pp' for shares and scores, 'pct' for levels (money, people).
String changeLine(List<(String, double, double)> points, String mode, {String unit = '', Trend? trend}) {
  // points: (label, year, value), sorted by year
  if (points.length < 2) return '';
  final a = points.first, b = points.last;
  final d = b.$3 - a.$3;
  final ppUnit = unit.contains('%') ? 'pp' : unit.replaceFirst(RegExp(r'^%\s*'), '').trim();
  final mag = math.max(a.$3.abs(), b.$3.abs());
  final dp = mag >= 100 ? 0 : mag >= 10 ? 1 : 2;
  String sign(double v) => v > 0 ? '+' : v < 0 ? '−' : '±';
  final u = ppUnit.isEmpty ? '' : ' $ppUnit';
  // A growth rate is already a change: "since 2019" between two years' rates
  // says little, so the caption gives the average rate instead.
  if (RegExp(r'yoy|growth', caseSensitive: false).hasMatch(unit)) {
    final avg = points.map((p) => p.$3).reduce((x, y) => x + y) / points.length;
    final r = (avg * 10).round() / 10;
    return 'average ${r == 0 ? '' : sign(r)}${_fmt(r.abs(), 1)}% a year, ${a.$1}–${b.$1}';
  }
  // The sign follows the number as shown: a change that rounds to zero reads
  // "no change", never "−0.00".
  double shown(double v, int k) => (v * math.pow(10, k)).round() / math.pow(10, k);
  String s;
  if (mode == 'pct' && a.$3 > 0) {
    final v = shown(d / a.$3 * 100, 1);
    s = v == 0 ? 'no change since ${a.$1}' : '${sign(v)}${_fmt(v.abs(), 1)}% since ${a.$1}';
  } else {
    final v = shown(d, dp);
    s = v == 0 ? 'no change since ${a.$1}' : '${sign(v)}${_fmt(v.abs(), dp)}$u since ${a.$1}';
  }
  if (trend != null) {
    if (trend.clear) {
      final per = mode == 'pct' && a.$3 > 0
          ? '${sign(trend.slope)}${_fmt((trend.slope / _median([for (final p in points) p.$3]) * 100).abs(), 1)}% a year'
          : '${sign(trend.slope)}${_fmt(trend.slope.abs(), dp >= 1 ? dp : 1)}$u a year';
      s += ' · trend $per';
    } else if (trend.n >= kTrendMinPoints) {
      s += ' · no clear trend';
    }
  }
  return s;
}
