import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../api.dart' show formatValue;
import '../theme.dart';
import 'chart_rules.dart';

/// A compact line chart of a value over time, following the chart rules in
/// chart_rules.dart (the website uses the same ones). The axis zooms to the
/// data so every change is visible. On top of the line:
///  - x is placed by year, so a gap of seven years looks like seven;
///  - straight segments between readings (a curve invents values between them);
///  - a band for the survey margin of error, when [margins] are given;
///  - IMF projections (years ≥ [projectedFrom]) on a shaded "forecast" stretch,
///    left out of the trend;
///  - a dashed Theil–Sen trend line where the direction is steady (≥ 6
///    readings, Mann–Kendall p < 0.05, same sign in both halves); compounding
///    levels (mode 'pct') are fitted on logs;
///  - a LOWESS curve over a faint line for long series (≥ 20 readings);
///  - a dotted median reference line, when it falls inside the range;
///  - a caption: change since the first reading and the trend, and a key.
///
/// Older call sites (`points`, `highlightPeriod`, `height`) keep working.
class TrendChart extends StatelessWidget {
  final List<(String, double)> points; // (period, value), sorted by period
  final String? highlightPeriod;
  final double height;

  /// Unit of the values ("%", "$", "years") — for the caption.
  final String unit;

  /// 'pp' (shares, scores: change in points) or 'pct' (levels: change in %).
  /// Null: points for a % or index unit, percent otherwise.
  final String? mode;

  /// 95% margin of error per point (same order as [points]); null where unknown.
  final List<double?>? margins;

  /// First projected year (IMF WEO: the release year and after).
  final double? projectedFrom;

  /// A reference value drawn as a dotted line, e.g. the median of all countries.
  final double? reference;
  final String referenceLabel;

  final bool showTrend;
  final bool showCaption;

  const TrendChart({
    super.key,
    required this.points,
    this.highlightPeriod,
    this.height = 180,
    this.unit = '',
    this.mode,
    this.margins,
    this.projectedFrom,
    this.reference,
    this.referenceLabel = 'Median',
    this.showTrend = true,
    this.showCaption = true,
  });

  String get _mode => mode ?? (isPointUnit(unit) ? 'pp' : 'pct');

  @override
  Widget build(BuildContext context) {
    final pts = <(String, double, double, double?)>[
      for (var i = 0; i < points.length; i++)
        if (points[i].$2.isFinite && periodYear(points[i].$1).isFinite)
          (points[i].$1, periodYear(points[i].$1), points[i].$2, margins != null && i < margins!.length ? margins![i] : null)
    ]..sort((a, b) => a.$2.compareTo(b.$2));

    if (pts.length < 2) {
      return SizedBox(
        height: height * 0.6,
        child: Center(
          child: Text(pts.isEmpty ? '—' : formatValue(pts.first.$3),
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: kAmber)),
        ),
      );
    }

    final proj = projectedFrom;
    final actual = [for (final p in pts) if (proj == null || p.$2 < proj) p];
    final hasProj = actual.length < pts.length;
    final trend = showTrend
        ? trendOf([for (final p in pts) (p.$2, p.$3)], projectedFrom: proj, log: _mode == 'pct')
        : null;
    final showLine = trend != null && trend.clear;
    final smooth = pts.length >= kSmoothMinPoints
        ? lowess([for (final p in pts) p.$2], [for (final p in pts) p.$3])
        : null;
    final hasBand = pts.any((p) => p.$4 != null);

    final values = [for (final p in pts) p.$3];
    final (lo, hi) = yDomain([
      ...values,
      for (final p in pts)
        if (p.$4 != null) ...[p.$3 - p.$4!, p.$3 + p.$4!],
      if (showLine) ...[trend.at(trend.x0), trend.at(trend.x1)],
    ]);
    // The reference joins the chart only when it is inside the data's range:
    // a far-off median would squash every change into a flat line.
    final refInside = reference != null && reference! >= lo && reference! <= hi;
    final ticks = niceTicks(lo, hi);
    final tickStep = ticks.length > 1 ? ticks[1] - ticks[0] : (hi - lo);

    final x0 = pts.first.$2, x1 = pts.last.$2;
    final xPad = (x1 - x0) * 0.03 + 0.2; // whole markers at the edges

    LineChartBarData series(List<(String, double, double, double?)> s,
            {Color? color, double width = 2.5, bool dots = true}) =>
        LineChartBarData(
          spots: [for (final p in s) FlSpot(p.$2, p.$3)],
          isCurved: false,
          color: color ?? kAmber,
          barWidth: width,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: dots,
            getDotPainter: (spot, pct, bar, i) {
              final hl = s[i].$1 == highlightPeriod;
              return FlDotCirclePainter(
                radius: hl ? 4 : 2.5,
                color: hl ? (color ?? kAmber) : kBgElev,
                strokeColor: color ?? kAmber,
                strokeWidth: 1.5,
              );
            },
          ),
        );

    final bars = <LineChartBarData>[];
    var bandLo = -1, bandHi = -1;
    if (hasBand) {
      final withM = [for (final p in pts) if (p.$4 != null) p];
      bars.add(LineChartBarData(
          spots: [for (final p in withM) FlSpot(p.$2, p.$3 - p.$4!)],
          color: Colors.transparent,
          barWidth: 0,
          dotData: const FlDotData(show: false)));
      bandLo = bars.length - 1;
      bars.add(LineChartBarData(
          spots: [for (final p in withM) FlSpot(p.$2, p.$3 + p.$4!)],
          color: Colors.transparent,
          barWidth: 0,
          dotData: const FlDotData(show: false)));
      bandHi = bars.length - 1;
    }
    final mainIndex = bars.length;
    bars.add(smooth != null
        ? series(pts, color: kAmber.withValues(alpha: 0.45), width: 1.2, dots: false)
        : series(pts));
    if (smooth != null) {
      bars.add(LineChartBarData(
        spots: [for (var i = 0; i < pts.length; i++) FlSpot(pts[i].$2, smooth[i])],
        isCurved: false,
        color: kAmber,
        barWidth: 2.8,
        dotData: const FlDotData(show: false),
      ));
    }
    if (showLine) {
      final steps = trend.log ? 24 : 1;
      bars.add(LineChartBarData(
        spots: [
          for (var i = 0; i <= steps; i++)
            FlSpot(trend.x0 + (trend.x1 - trend.x0) * i / steps, trend.at(trend.x0 + (trend.x1 - trend.x0) * i / steps))
        ],
        isCurved: false,
        color: kTextDim,
        barWidth: 1.5,
        dashArray: [6, 4],
        dotData: const FlDotData(show: false),
      ));
    }

    final firstProj = hasProj ? pts[actual.length].$2 : null;
    final projStart = firstProj == null ? null : (actual.isEmpty ? x0 - xPad : (actual.last.$2 + firstProj) / 2);

    String fmtRef(double v) => '${formatValue(v)}${unit.contains('%') ? '%' : ''}';
    final change = showCaption
        ? changeLine([for (final p in actual.isEmpty ? pts : actual) (p.$1, p.$2, p.$3)], _mode, unit: unit, trend: trend)
        : '';
    final key = <String>[
      if (hasBand) 'band: margin of error (95%, about)',
      if (smooth != null) 'thick: smoothed',
      if (showLine) 'dashed: trend',
      if (refInside) 'dotted: $referenceLabel',
      if (hasProj) 'shaded: IMF forecast',
    ];
    final refNote = reference != null && !refInside
        ? '$referenceLabel: ${fmtRef(reference!)} (${reference! < lo ? 'below' : 'above'} this range)'
        : '';

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      LayoutBuilder(builder: (context, box) {
        // Year labels: each reading's own label, kept only where it does not
        // touch a neighbour (widths estimated for 10px Inter).
        final plotW = (box.maxWidth.isFinite ? box.maxWidth : 340) - 46;
        final pxPerYear = plotW / ((x1 - x0) + 2 * xPad);
        double w(String l) => l.length * 5.8 + 8;
        double centre((String, double, double, double?) p) {
          final c = (p.$2 - x0 + xPad) * pxPerYear;
          return c.clamp(w(p.$1) / 2, plotW - w(p.$1) / 2).toDouble();
        }

        final kept = <(String, double, double, double?)>[];
        for (final p in [pts.first, pts.last, ...pts.sublist(1, pts.length - 1)]) {
          if (kept.every((q) => (centre(p) - centre(q)).abs() >= (w(p.$1) + w(q.$1)) / 2 + 6)) kept.add(p);
        }
        final labelled = {for (final p in kept) p.$2: p.$1};

        return SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minX: x0 - xPad,
              maxX: x1 + xPad,
              minY: lo,
              maxY: hi,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: tickStep,
                getDrawingHorizontalLine: (v) => v.abs() < tickStep * 1e-6
                    ? FlLine(color: kTextDim.withValues(alpha: 0.6), strokeWidth: 1)
                    : FlLine(color: kBorder, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
              rangeAnnotations: RangeAnnotations(verticalRangeAnnotations: [
                if (projStart != null)
                  VerticalRangeAnnotation(x1: projStart, x2: x1 + xPad, color: kTextDim.withValues(alpha: 0.12)),
              ]),
              betweenBarsData: [
                if (hasBand) BetweenBarsData(fromIndex: bandLo, toIndex: bandHi, color: kAmber.withValues(alpha: 0.16)),
              ],
              extraLinesData: ExtraLinesData(horizontalLines: [
                if (refInside)
                  HorizontalLine(
                    y: reference!,
                    color: kTextDim.withValues(alpha: 0.7),
                    strokeWidth: 1,
                    dashArray: [2, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: TextStyle(fontSize: 10, color: kTextDim),
                      labelResolver: (_) => '$referenceLabel: ${fmtRef(reference!)}',
                    ),
                  ),
              ]),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    interval: tickStep,
                    getTitlesWidget: (v, meta) {
                      // Only the round ticks: fl_chart also offers the bare min and max.
                      if (!ticks.any((t) => (t - v).abs() < tickStep * 1e-6)) return const SizedBox.shrink();
                      return Text('${formatValue(v)}${unit.contains('%') ? '%' : ''}',
                          style: TextStyle(fontSize: 10, color: kTextDim));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 0.5,
                    getTitlesWidget: (v, meta) {
                      final hit = labelled.entries.where((e) => (e.key - v).abs() < 0.25);
                      if (hit.isEmpty) return const SizedBox.shrink();
                      // fl_chart 0.69 API; from 0.70 the first argument is `meta: meta`.
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 4,
                        fitInside: SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 0),
                        child: Text(hit.first.value, style: TextStyle(fontSize: 10, color: kTextDim)),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => kBgCard,
                  getTooltipItems: (touched) => touched.map((s) {
                    if (s.barIndex != mainIndex) return null;
                    final p = pts.where((q) => (q.$2 - s.x).abs() < 1e-9);
                    if (p.isEmpty) return null;
                    final q = p.first;
                    final tag = proj != null && q.$2 >= proj ? ' (IMF forecast)' : '';
                    final m = q.$4 != null ? ' ± ${formatValue(q.$4!)}' : '';
                    return LineTooltipItem(
                      '${q.$1}$tag\n${formatValue(q.$3)}$m',
                      TextStyle(color: kText, fontSize: 12, fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: bars,
            ),
          ),
        );
      }),
      if (change.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(change, style: TextStyle(fontSize: 12, color: kText)),
        ),
      if (refNote.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(refNote, style: TextStyle(fontSize: 11, color: kTextDim)),
        ),
      if (key.isNotEmpty && showCaption)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(key.join(' · '), style: TextStyle(fontSize: 11, color: kTextDim)),
        ),
    ]);
  }
}
