import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';

/// Median of [v] (empty → NaN). Unweighted: every country counts once.
double medianOf(Iterable<double> v) {
  final s = v.toList()..sort();
  final n = s.length;
  if (n == 0) return double.nan;
  return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

/// "▏Median 168 · mean 182 · 185 countries, each counted once": the middle of
/// the sample next to its average, so a single bar has something to be read
/// against (owner, 14 Nov 2026). The leading tick keys the median tick drawn
/// in bar tracks. Shared by the ranking, the map view, stories and the share
/// card so every ranking carries it (owner, 15 Nov 2026).
class SampleStats extends StatelessWidget {
  final List<double> values;
  final String unit;
  final Color? color;
  final Color? tickColor;
  final double fontSize;
  final String prefix;
  const SampleStats(
      {super.key,
      required this.values,
      required this.unit,
      this.color,
      this.tickColor,
      this.fontSize = 12,
      this.prefix = ''});

  @override
  Widget build(BuildContext context) {
    if (values.length < 3) return const SizedBox.shrink();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final u = unit.contains('%') ? '%' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
          TextSpan(children: [
            WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                    width: 2,
                    height: fontSize,
                    margin: const EdgeInsets.only(right: 6),
                    color: tickColor ?? kText.withValues(alpha: 0.55))),
            TextSpan(
                text: '${prefix}Median ${formatValue(medianOf(values))}$u · mean ${formatValue(mean)}$u · '
                    '${values.length} countries, each counted once'),
          ]),
          style: TextStyle(fontSize: fontSize, color: color ?? kTextDim)),
    );
  }
}
