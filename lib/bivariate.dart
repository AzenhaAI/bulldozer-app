import 'package:flutter/material.dart';

/// Bivariate choropleth helpers — a 1:1 port of the site's `src/lib/bivariate.ts`
/// so the app and the web colour the same country the same way.
///
/// Two indicators are each split into terciles (low/mid/high) and blended as
/// two hues on a dark base: X drives amber, Y drives blue, so a country that is
/// high on both reads brightest.
const _base = [40, 42, 48];
const _amber = [255, 176, 0]; // X axis
const _blue = [80, 140, 230]; // Y axis

/// Colour for class (xi, yi), each 0..2.
Color bivColor(int xi, int yi) {
  int ch(int i) => (_base[i] +
          (_amber[i] - _base[i]) * (xi / 2) +
          (_blue[i] - _base[i]) * (yi / 2))
      .round()
      .clamp(0, 255);
  return Color.fromARGB(255, ch(0), ch(1), ch(2));
}

/// Tercile thresholds [t1, t2] for a list of values.
(double, double) terciles(List<double> values) {
  final s = [...values]..sort();
  double q(double p) => s[(p * s.length).floor().clamp(0, s.length - 1)];
  return (q(1 / 3), q(2 / 3));
}

int classify(double v, (double, double) t) =>
    v <= t.$1 ? 0 : (v <= t.$2 ? 1 : 2);

/// The 3×3 key shown under a bivariate map: X (amber) →, Y (blue) ↑.
class BivariateLegend extends StatelessWidget {
  final String xLabel, yLabel;
  const BivariateLegend({super.key, required this.xLabel, required this.yLabel});

  @override
  Widget build(BuildContext context) {
    const dim = TextStyle(fontSize: 9, color: Color(0xFF9AA1A9));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotatedBox(
          quarterTurns: 3,
          child: Text(yLabel,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: dim),
        ),
        const SizedBox(width: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var y = 2; y >= 0; y--)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var x = 0; x < 3; x++)
                    Container(width: 20, height: 20, color: bivColor(x, y)),
                ],
              ),
            const SizedBox(height: 3),
            SizedBox(
              width: 60,
              child: Text(xLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: dim),
            ),
          ],
        ),
      ],
    );
  }
}
