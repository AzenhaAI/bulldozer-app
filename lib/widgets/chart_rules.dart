// Chart rules for time series — the same logic as the website's
// src/lib/trend.ts; both are checked against SciPy, pymannkendall and
// statsmodels (test/trend_vectors.json, test/lowess_vectors.json,
// `dart run tools/check_chart_rules.dart`).
//
// Owner's choice (10 Nov 2026): the axis zooms to the data so every change is
// visible — no forced zero, no minimum span, a flat series is still a chart.
//  - x by time: "2013" and "2020" sit seven years apart, not one step.
//  - Round axis ticks, and a 0 line whenever values cross zero.
//  - Change in words: first → last; for growth rates the compound average.
//  - Trend line: Theil–Sen slope (median of pairwise slopes), over the
//    observed years only, when ≥ 6 readings, Mann–Kendall p < 0.05 and the
//    same direction in both halves (no line through a rise-then-fall);
//    levels that compound (money, people) are fitted on log(y).
//  - LOWESS curve for long series (≥ 20 readings).
//  - Survey margins of error as a band; IMF projections shaded; a median
//    reference line.
//
// Pure Dart — no Flutter import — so it runs under plain `dart`.
import 'dart:math' as math;

/// Calendar position of a period label: "2021" → 2021, "2021–2023" → 2022.
double periodYear(String p) {
  final m = RegExp(r'\d{4}').allMatches(p).map((e) => double.parse(e.group(0)!)).toList();
  if (m.isEmpty) return double.nan;
  return m.length > 1 ? (m.first + m.last) / 2 : m.first;
}

/// y-axis domain zoomed to the data (pass margins, trend ends and an in-range
/// reference with the values), 8% padding.
(double, double) yDomain(List<double> values) {
  final v = values.where((x) => x.isFinite).toList();
  final lo = v.reduce(math.min), hi = v.reduce(math.max);
  if (hi == lo) {
    final p = hi.abs() * 0.1 == 0 ? 1.0 : hi.abs() * 0.1;
    return (lo - p, hi + p);
  }
  final pad = (hi - lo) * 0.08;
  return (lo - pad, hi + pad);
}

/// Round ticks (1, 2, 2.5, 5 × 10^k) inside [lo, hi]; 0 included when the range crosses it.
List<double> niceTicks(double lo, double hi, {int count = 4}) {
  final raw = (hi - lo) / count;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final step = [1, 2, 2.5, 5, 10].map((m) => m * mag).firstWhere((s) => s >= raw, orElse: () => 10 * mag);
  final out = <double>[];
  for (var t = (lo / step).ceil() * step; t <= hi + step * 1e-9; t += step) {
    out.add(double.parse(((t / step).round() * step).toStringAsPrecision(12)));
  }
  if (lo < 0 && hi > 0 && !out.contains(0)) out.add(0);
  return out..sort();
}

double _median(List<double> a) {
  final s = [...a]..sort();
  final n = s.length;
  return n.isOdd ? s[(n - 1) ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

/// Median of a list (exported for panel medians).
double medianOf(List<double> a) => _median(a);

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
const kSmoothMinPoints = 20;
const kSmoothFrac = 0.3;

class Trend {
  final double slope, intercept, p, x0, x1;
  final int n;

  /// A steady direction: ≥ 6 readings, Mann–Kendall p < 0.05, same sign in both halves.
  final bool clear;

  /// Fitted on log(y): levels that grow by a percentage.
  final bool log;
  const Trend(this.slope, this.intercept, this.p, this.n, this.clear, this.x0, this.x1, this.log);

  /// The trend's value at x (exponential when fitted on logs).
  double at(double x) => log ? math.exp(intercept + slope * x) : intercept + slope * x;

  /// Change per year: points for a linear fit, percent for a log fit.
  double get rate => log ? (math.exp(slope) - 1) * 100 : slope;
}

/// Points as (year, value); [projectedFrom] leaves projections out of the fit;
/// [log] fits on log(y) when every value is above 0.
Trend? trendOf(List<(double, double)> points, {double? projectedFrom, bool log = false}) {
  final pts = points
      .where((p) => p.$1.isFinite && p.$2.isFinite && (projectedFrom == null || p.$1 < projectedFrom))
      .toList()
    ..sort((a, b) => a.$1.compareTo(b.$1));
  if (pts.length < 3) return null;
  final useLog = log && pts.every((p) => p.$2 > 0);
  final xs = [for (final p in pts) p.$1], ys = [for (final p in pts) useLog ? math.log(p.$2) : p.$2];
  final ts = theilSen(xs, ys);
  final mk = mannKendall(ys);
  // The same direction in each half: a rise then a fall is not one trend.
  final h = pts.length ~/ 2;
  final s1 = theilSen(xs.sublist(0, h), ys.sublist(0, h)).slope;
  final s2 = theilSen(xs.sublist(xs.length - h), ys.sublist(ys.length - h)).slope;
  final steady = s1.sign == ts.slope.sign && s2.sign == ts.slope.sign;
  return Trend(ts.slope, ts.intercept, mk.p, pts.length,
      pts.length >= kTrendMinPoints && mk.p < kTrendP && ts.slope != 0 && steady, xs.first, xs.last, useLog);
}

/// LOWESS (Cleveland 1979; local linear, tricube weights over the
/// k = floor(frac·n) nearest readings, no robustness passes) — the same as
/// statsmodels' lowess(y, x, frac, it=0, delta=0).
List<double> lowess(List<double> xs, List<double> ys, {double frac = kSmoothFrac}) {
  final n = xs.length;
  final k = math.min(n, math.max(2, (frac * n + 1e-10).floor()));
  final out = List<double>.filled(n, 0);
  var left = 0, right = k;
  for (var i = 0; i < n; i++) {
    while (right < n && xs[i] - xs[left] > xs[right] - xs[i]) {
      left++;
      right++;
    }
    final h = math.max(xs[i] - xs[left], xs[right - 1] - xs[i]);
    var sw = 0.0, sx = 0.0, sy = 0.0;
    final w = <double>[];
    for (var j = left; j < right; j++) {
      // Cleveland's thresholds: within 0.001·h weight 1, beyond 0.999·h weight 0.
      final r = (xs[j] - xs[i]).abs();
      final wj = r <= 0.001 * h ? 1.0 : r > 0.999 * h ? 0.0 : math.pow(1 - math.pow(r / h, 3), 3).toDouble();
      w.add(wj);
      sw += wj;
      sx += wj * xs[j];
      sy += wj * ys[j];
    }
    if (sw <= 0) {
      out[i] = ys[i];
      continue;
    }
    final mx = sx / sw, my = sy / sw;
    var sxx = 0.0, sxy = 0.0;
    for (var j = left; j < right; j++) {
      final wj = w[j - left];
      sxx += wj * (xs[j] - mx) * (xs[j] - mx);
      sxy += wj * (xs[j] - mx) * (ys[j] - my);
    }
    out[i] = sxx > 1e-12 * sw ? my + (sxy / sxx) * (xs[i] - mx) : my;
  }
  return out;
}

String _fmt(double v, int dp) {
  final s = v.toStringAsFixed(dp);
  final parts = s.split('.');
  final int = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return parts.length > 1 ? '$int.${parts[1]}' : int;
}

// Round half away from zero (Dart's round), the same on the website.
double _roundAway(double v, int k) => (v * math.pow(10, k)).round() / math.pow(10, k);

/// Whether a unit's change reads in points (shares, indices) rather than percent.
bool isPointUnit(String unit) =>
    unit.contains('%') || RegExp(r'index|score|mean|0–|0-').hasMatch(unit.toLowerCase());

/// One line under a chart: "−1.6 pp since 2013 · trend −0.2 pp per year".
/// [mode] 'pp' for shares and scores, 'pct' for levels (money, people).
/// Growth-rate units ("% YoY"): the compound average rate instead.
String changeLine(List<(String, double, double)> points, String mode, {String unit = '', Trend? trend}) {
  // points: (label, year, value), sorted by year
  if (points.length < 2) return '';
  final a = points.first, b = points.last;
  final ppUnit = unit.contains('%') ? 'pp' : unit.replaceFirst(RegExp(r'^%\s*'), '').trim();
  final u = ppUnit.isEmpty ? '' : ' $ppUnit';
  final mag = math.max(a.$3.abs(), b.$3.abs());
  final dp = mag >= 100 ? 0 : mag >= 10 ? 1 : 2;
  String sign(double v) => v > 0 ? '+' : v < 0 ? '−' : '';
  if (RegExp(r'yoy|growth', caseSensitive: false).hasMatch(unit)) {
    // Yearly rates compound: a plain average hid Macao's 12.7% fall.
    final g = points.fold<double>(1, (t, p) => t * (1 + p.$3 / 100));
    if (g <= 0) return '';
    final r = _roundAway((math.pow(g, 1 / points.length) - 1) * 100, 1);
    return 'compound average ${sign(r)}${_fmt(r.abs(), 1)}% per year, ${a.$1}–${b.$1}';
  }
  String s;
  if (mode == 'pct' && a.$3 > 0) {
    final v = _roundAway((b.$3 - a.$3) / a.$3 * 100, 1);
    s = v == 0 ? 'no change since ${a.$1}' : '${sign(v)}${_fmt(v.abs(), 1)}% since ${a.$1}';
  } else {
    final v = _roundAway(b.$3 - a.$3, dp);
    s = v == 0 ? 'no change since ${a.$1}' : '${sign(v)}${_fmt(v.abs(), dp)}$u since ${a.$1}';
  }
  if (trend != null) {
    if (trend.clear) {
      final r = trend.rate;
      final k = math.max(dp, 1);
      s += trend.log
          ? ' · trend ${sign(r)}${_fmt(_roundAway(r, 1).abs(), 1)}% per year'
          : ' · trend ${sign(r)}${_fmt(_roundAway(r, k).abs(), k)}$u per year';
    } else if (trend.n >= kTrendMinPoints) {
      s += ' · no steady trend';
    }
  }
  return s;
}
