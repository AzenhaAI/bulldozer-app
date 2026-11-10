import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../api.dart' show formatValue;
import '../theme.dart';
import 'chart_rules.dart';

/// A compact line chart of a value over time, following the chart rules in
/// chart_rules.dart (the website uses the same ones):
///  - a flat series is a number and "unchanged since …", not a chart;
///  - x is placed by year, so a gap of seven years looks like seven;
///  - straight segments between readings (a curve invents values between them);
///  - the y-axis never shows negatives for data that has none; the soft fill
///    is drawn only when the axis starts at zero, where an area is honest;
///  - a dashed Theil–Sen trend line over the observed years, only with ≥ 6
///    readings and a consistent direction (Mann–Kendall p < 0.05);
///  - projections (years ≥ [projectedFrom]) dashed and left out of the trend;
///  - an optional reference line, e.g. the world median;
///  - one caption line: change since the first reading, and the trend.
///
/// Older call sites (`points`, `highlightPeriod`, `height`) keep working; the
/// new parameters only sharpen the result.
class TrendChart extends StatelessWidget {
  final List<(String, double)> points; // (period, value), sorted by period
  final String? highlightPeriod;
  final double height;

  /// Unit of the values ("%", "$", "years") — for the caption.
  final String unit;

  /// 'pp' (shares, scores: change in points) or 'pct' (levels: change in %).
  /// Null: points for a % or index unit, percent otherwise.
  final String? mode;

  /// Whether the whole dataset has no negative values; null reads it from
  /// these points.
  final bool? nonNegative;

  /// First projected year (IMF WEO: the release year and after).
  final double? projectedFrom;

  /// A reference value drawn as a faint dashed line, with its label.
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
    this.nonNegative,
    this.projectedFrom,
    this.reference,
    this.referenceLabel = 'Median',
    this.showTrend = true,
    this.showCaption = true,
  });

  String get _mode =>
      mode ?? (unit.contains('%') || RegExp(r'index|score|mean|0–|0-').hasMatch(unit.toLowerCase()) ? 'pp' : 'pct');

  @override
  Widget build(BuildContext context) {
    final pts = [
      for (final p in points)
        if (p.$2.isFinite && periodYear(p.$1).isFinite) (p.$1, periodYear(p.$1), p.$2),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    final values = [for (final p in pts) p.$3];

    // Rule 1: one reading, or a flat series — the number, not a chart.
    if (pts.length < 2 || isFlat(values)) {
      return SizedBox(
        height: height * 0.6,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pts.isEmpty ? '—' : formatValue(pts.last.$3),
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: kAmber),
              ),
              if (pts.length >= 2)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('unchanged since ${pts.first.$1}', style: TextStyle(fontSize: 12, color: kTextDim)),
                ),
            ],
          ),
        ),
      );
    }

    final nonNeg = nonNegative ?? nonNegativeFrom(values);
    final trend = showTrend ? trendOf([for (final p in pts) (p.$2, p.$3)], projectedFrom: projectedFrom) : null;
    final domainValues = [
      ...values,
      ?reference,
      if (trend != null && trend.clear) ...[trend.at(trend.x0), trend.at(trend.x1)],
    ];
    final (lo, hi) = yDomain(domainValues, nonNegative: nonNeg);
    final fill = lo == 0; // an area only where the axis starts at zero

    final proj = projectedFrom;
    final actual = [
      for (final p in pts)
        if (proj == null || p.$2 < proj) p,
    ];
    final projected = [
      for (final p in pts)
        if (proj != null && p.$2 >= proj) p,
    ];
    if (actual.isNotEmpty && projected.isNotEmpty) projected.insert(0, actual.last);

    final x0 = pts.first.$2, x1 = pts.last.$2;
    LineChartBarData line(List<(String, double, double)> s, {List<int>? dash, bool dots = true}) => LineChartBarData(
      spots: [for (final p in s) FlSpot(p.$2, p.$3)],
      isCurved: false,
      color: kAmber,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dashArray: dash,
      dotData: FlDotData(
        show: dots,
        getDotPainter: (spot, pct, bar, i) {
          final hl = s[i].$1 == highlightPeriod;
          return FlDotCirclePainter(
            radius: hl ? 4 : 2.5,
            color: hl ? kAmber : kBgElev,
            strokeColor: kAmber,
            strokeWidth: 1.5,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: fill && dash == null,
        gradient: LinearGradient(
          colors: [kAmber.withValues(alpha: 0.22), kAmber.withValues(alpha: 0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );

    final bars = <LineChartBarData>[
      if (actual.length >= 2) line(actual) else if (actual.length == 1) line(actual),
      if (projected.length >= 2) line(projected, dash: [5, 4]),
      if (trend != null && trend.clear)
        LineChartBarData(
          spots: [FlSpot(trend.x0, trend.at(trend.x0)), FlSpot(trend.x1, trend.at(trend.x1))],
          isCurved: false,
          color: kTextDim,
          barWidth: 1.5,
          dashArray: [6, 4],
          dotData: const FlDotData(show: false),
        ),
    ];
    final trendBar = trend != null && trend.clear ? bars.length - 1 : -1;

    final caption = showCaption
        ? changeLine([for (final p in actual.isEmpty ? pts : actual) p], _mode, unit: unit, trend: trend)
        : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            // Year labels: each reading's own label, kept only where it does not
            // touch a neighbour. Widths are estimated for 10px Inter; the first
            // and last labels sit inside the edges, so their centres move inward.
            final plotW = (box.maxWidth.isFinite ? box.maxWidth : 340) - 42;
            final pxPerYear = x1 == x0 ? 0.0 : plotW / (x1 - x0);
            double w(String l) => l.length * 5.8 + 8;
            double centre((String, double, double) p) {
              final c = (p.$2 - x0) * pxPerYear;
              return c.clamp(w(p.$1) / 2, plotW - w(p.$1) / 2).toDouble();
            }

            final kept = <(String, double, double)>[];
            for (final p in [pts.first, pts.last, ...pts.sublist(1, pts.length - 1)]) {
              if (kept.every((q) => (centre(p) - centre(q)).abs() >= (w(p.$1) + w(q.$1)) / 2 + 6)) kept.add(p);
            }
            final labelled = {for (final p in kept) p.$2: p.$1};
            return SizedBox(
              height: height,
              child: LineChart(
                LineChartData(
                  minX: x0 == x1 ? x0 - 1 : x0,
                  maxX: x0 == x1 ? x1 + 1 : x1,
                  minY: lo,
                  maxY: hi,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: kBorder, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (reference != null)
                        HorizontalLine(
                          y: reference!,
                          color: kTextDim.withValues(alpha: 0.7),
                          strokeWidth: 1,
                          dashArray: [2, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            style: TextStyle(fontSize: 10, color: kTextDim),
                            labelResolver: (_) => '$referenceLabel ${formatValue(reference!)}',
                          ),
                        ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (v, meta) {
                          // fl_chart also labels the exact min and max; skip those
                          // when they would crowd a regular tick.
                          if ((v == meta.min || v == meta.max) &&
                              (v / meta.appliedInterval).roundToDouble() * meta.appliedInterval != v) {
                            return const SizedBox.shrink();
                          }
                          return Text(formatValue(v), style: TextStyle(fontSize: 10, color: kTextDim));
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
                          // fitInside keeps the first and last labels from being cut at the edges.
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
                        if (s.barIndex == trendBar) return null;
                        final p = pts.where((q) => (q.$2 - s.x).abs() < 1e-9);
                        final label = p.isEmpty ? '' : p.first.$1;
                        final tag = proj != null && s.x >= proj ? ' (projection)' : '';
                        return LineTooltipItem(
                          '$label$tag\n${formatValue(s.y)}',
                          TextStyle(color: kText, fontSize: 12, fontWeight: FontWeight.w600),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: bars,
                ),
              ),
            );
          },
        ),
        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(caption, style: TextStyle(fontSize: 12, color: kTextDim)),
          ),
      ],
    );
  }
}
