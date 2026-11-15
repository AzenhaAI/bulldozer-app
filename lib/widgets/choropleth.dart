import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../api.dart' show formatValue;
import '../theme.dart';

class GeoCountry {
  final String iso;
  final String name;
  final List<List<List<Offset>>> polys; // polygon -> ring -> points (geo space)
  GeoCountry(this.iso, this.name, this.polys);
}

class WorldGeo {
  final double w;
  final double h;
  final List<GeoCountry> countries;
  WorldGeo(this.w, this.h, this.countries);
}

WorldGeo? _cached;

/// Loads and caches the pre-projected world geometry (assets/world.json).
Future<WorldGeo> loadWorldGeo() async {
  if (_cached != null) return _cached!;
  final j = jsonDecode(await rootBundle.loadString('assets/world.json'));
  final countries = <GeoCountry>[];
  for (final c in (j['countries'] as List)) {
    final polys = <List<List<Offset>>>[];
    for (final poly in (c['polys'] as List)) {
      final rings = <List<Offset>>[];
      for (final ring in (poly as List)) {
        rings.add([
          for (final p in (ring as List))
            Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
        ]);
      }
      polys.add(rings);
    }
    countries.add(GeoCountry(c['iso'] ?? '', c['name'] ?? '', polys));
  }
  return _cached = WorldGeo(
    (j['w'] as num).toDouble(),
    (j['h'] as num).toDouble(),
    countries,
  );
}

/// Legend for [Choropleth]: stepped swatches of the five quantile classes
/// between the [low] and [high] captions, plus a hatched "No data" swatch.
///
/// Give it the same [values] the map gets and it prints the class breaks under
/// the swatches (computed by [Choropleth.breaksFor], so legend and map agree);
/// [unit] is shown next to "No data" ('%' is appended to the numbers instead).
/// Without [values] it draws the swatches with captions only.
class ChoroLegend extends StatelessWidget {
  final String low;
  final String high;
  final Iterable<double>? values;
  final String? unit;
  const ChoroLegend({
    super.key,
    required this.low,
    required this.high,
    this.values,
    this.unit,
  });

  String _fmt(double v) {
    final s = formatValue(v);
    return unit?.trim() == '%' ? '$s%' : s;
  }

  @override
  Widget build(BuildContext context) {
    final dim = TextStyle(fontSize: 11, color: kTextDim);
    final breaks = values == null
        ? const <double>[]
        : Choropleth.breaksFor(values!);
    final hasValues = values != null && values!.any((v) => v.isFinite);
    final n = hasValues ? breaks.length + 1 : Choropleth.classes;
    final colors = [for (var k = 0; k < n; k++) Choropleth.classColor(k, n)];

    final swatches = Row(
      children: [
        for (var k = 0; k < n; k++)
          Expanded(
            child: Container(
              height: 10,
              margin: EdgeInsets.only(right: k == n - 1 ? 0 : 2),
              decoration: BoxDecoration(
                color: colors[k],
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(k == 0 ? 3 : 0),
                  right: Radius.circular(k == n - 1 ? 3 : 0),
                ),
              ),
            ),
          ),
      ],
    );

    final noData = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _NoDataSwatch(),
        const SizedBox(width: 5),
        Text('No data', style: dim),
      ],
    );

    if (!hasValues) {
      return Row(
        children: [
          Text(low, style: dim),
          const SizedBox(width: 8),
          Expanded(child: swatches),
          const SizedBox(width: 8),
          Text(
            high,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kAmber,
            ),
          ),
          const SizedBox(width: 12),
          noData,
        ],
      );
    }

    // Break values sit under the boundaries between swatches.
    final breakLabels = SizedBox(
      height: 14,
      child: LayoutBuilder(
        builder: (ctx, cons) {
          const labelW = 56.0;
          final w = cons.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < breaks.length; i++)
                Positioned(
                  left: (w * (i + 1) / n - labelW / 2).clamp(
                    0.0,
                    max(0.0, w - labelW),
                  ),
                  top: 0,
                  width: labelW,
                  child: Text(
                    _fmt(breaks[i]),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 10,
                      color: kTextDim,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    final u = unit?.trim() ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(low, style: dim),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: swatches,
                  ),
                  const SizedBox(height: 3),
                  breakLabels,
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              high,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kAmber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            noData,
            const Spacer(),
            if (u.isNotEmpty && u != '%')
              Flexible(
                child: Text(
                  u,
                  style: dim,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Small no-data swatch: the map's neutral grey with its diagonal hatch.
class _NoDataSwatch extends StatelessWidget {
  const _NoDataSwatch();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 14,
        height: 10,
        child: CustomPaint(painter: _HatchSwatchPainter(isLight)),
      ),
    );
  }
}

class _HatchSwatchPainter extends CustomPainter {
  final bool light;
  _HatchSwatchPainter(this.light);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = Choropleth.noDataColor);
    _paintHatch(canvas, rect);
  }

  @override
  bool shouldRepaint(_HatchSwatchPainter old) => old.light != light;
}

/// Diagonal (/) hatch lines over [rect]; callers clip to the shape first.
/// Lines sit on a canvas-wide grid (x + y = n · spacing), so neighbouring
/// hatched shapes line up.
void _paintHatch(Canvas canvas, Rect rect, {double spacing = 4}) {
  final p = Paint()
    ..color = Choropleth.noDataHatchColor
    ..strokeWidth = 0.8
    ..isAntiAlias = true;
  final end = rect.right + rect.bottom;
  for (
    var c = ((rect.left + rect.top) / spacing).floor() * spacing;
    c <= end;
    c += spacing
  ) {
    canvas.drawLine(
      Offset(c - rect.bottom, rect.bottom),
      Offset(c - rect.top, rect.top),
      p,
    );
  }
}

/// A labelled point in the map's geo space (pre-projected, like world.json) —
/// used to mark a country's capital on the locator map.
class CapitalMarker {
  final String name;
  final double x;
  final double y;
  const CapitalMarker(this.name, this.x, this.y);
}

/// A world choropleth: fills each country by [values] (ISO3 → value) in five
/// quantile classes on the amber ramp; hatched grey where there's no data.
/// Tap a country to drill in. [ChoroLegend] with the same values shows the
/// same classes.
class Choropleth extends StatefulWidget {
  /// Number of quantile classes (fewer when the data has too few distinct
  /// values to fill them).
  static const classes = 5;

  // Sequential amber ramps, low → high, spaced roughly evenly in CIELAB L*.
  // Light theme: light → dark (L* ≈ 92, 78, 64, 47, 31).
  static const _rampLight = [
    Color(0xFFFCE7A8),
    Color(0xFFF2B640),
    Color(0xFFD98A00),
    Color(0xFFA65E00),
    Color(0xFF6F3B00),
  ];
  // Dark theme: dark → bright (L* ≈ 33, 47, 62, 76, 90). The lowest class is
  // a saturated brown, well above the no-data grey (L* ≈ 19).
  static const _rampDark = [
    Color(0xFF6B4500),
    Color(0xFF9A6300),
    Color(0xFFCC8600),
    Color(0xFFF5AE1E),
    Color(0xFFFFE08A),
  ];

  /// The five class colours, low → high, for the active theme.
  static List<Color> get ramp => isLight ? _rampLight : _rampDark;

  /// Neutral "land" grey for countries without data — no hue, so it can't be
  /// read as the (warm) lowest class; drawn with a hatch on top.
  static Color get noDataColor =>
      isLight ? const Color(0xFFC8C5BE) : const Color(0xFF2A2F36);

  /// Hatch line colour over [noDataColor].
  static Color get noDataHatchColor =>
      isLight ? const Color(0x40000000) : const Color(0x33FFFFFF);

  /// Quantile class breaks for [values] (non-finite values ignored): the
  /// ascending inner thresholds, at most [classes] − 1 of them. A value v is
  /// in class k = number of breaks ≤ v, so class 0 is "under breaks[0]" and
  /// the last class is "breaks.last and over". Duplicate thresholds (ties)
  /// are merged, so there can be fewer classes; empty input gives [].
  static List<double> breaksFor(Iterable<double> values) {
    final v = values.where((x) => x.isFinite).toList()..sort();
    if (v.isEmpty) return const [];
    final out = <double>[];
    for (var i = 1; i < classes; i++) {
      final b = v[min(v.length - 1, (v.length * i / classes).floor())];
      // A break at the minimum would leave class 0 empty; equal breaks would
      // leave a class between them empty.
      if (b > v.first && (out.isEmpty || b > out.last)) out.add(b);
    }
    return out;
  }

  /// Class index of [v] for [breaks] from [breaksFor].
  static int classOf(double v, List<double> breaks) {
    var k = 0;
    while (k < breaks.length && v >= breaks[k]) {
      k++;
    }
    return k;
  }

  /// Colour of class [k] out of [n] classes: five classes use the full ramp,
  /// fewer take an evenly spread subset (one class sits mid-ramp).
  static Color classColor(int k, int n) {
    final r = ramp;
    if (n <= 1) return r[r.length ~/ 2];
    if (n >= r.length) return r[k.clamp(0, r.length - 1)];
    return r[((k * (r.length - 1)) / (n - 1)).round().clamp(0, r.length - 1)];
  }

  /// Fill colour for value [v] given [breaks] from [breaksFor].
  static Color colorFor(double v, List<double> breaks) =>
      classColor(classOf(v, breaks), breaks.length + 1);

  final Map<String, double> values;

  /// Pre-computed fill per ISO. When set it wins over the amber ramp — used by
  /// the bivariate map, which blends two indicators into one colour.
  final Map<String, Color>? colorOverride;
  final String? highlightIso;
  final String? zoomIso; // zoom the view to this country (locator map)
  final CapitalMarker? capital; // labelled dot, like the site's CountryPanel
  final void Function(String iso, String name)? onTap;
  const Choropleth({
    super.key,
    required this.values,
    this.colorOverride,
    this.highlightIso,
    this.zoomIso,
    this.capital,
    this.onTap,
  });

  @override
  State<Choropleth> createState() => _ChoroplethState();
}

class _ChoroplethState extends State<Choropleth> {
  WorldGeo? _geo;

  @override
  void initState() {
    super.initState();
    loadWorldGeo().then((g) {
      if (mounted) setState(() => _geo = g);
    });
  }

  bool _pointInRing(List<Offset> ring, double x, double y) {
    bool inside = false;
    final n = ring.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = ring[i].dx, yi = ring[i].dy, xj = ring[j].dx, yj = ring[j].dy;
      if (((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }

  GeoCountry? _hitTest(double gx, double gy) {
    for (final c in _geo!.countries) {
      for (final poly in c.polys) {
        if (poly.isNotEmpty && _pointInRing(poly[0], gx, gy)) return c;
      }
    }
    return null;
  }

  GeoCountry? _byIso(String iso) {
    for (final c in _geo!.countries) {
      if (c.iso == iso) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final geo = _geo;
    if (geo == null) {
      return AspectRatio(
        aspectRatio: 2,
        child: Center(child: CircularProgressIndicator(color: kAmber)),
      );
    }
    final breaks = Choropleth.breaksFor(widget.values.values);

    // View region in geo coords: whole world, or zoomed to one country.
    final aspect = geo.w / geo.h;
    double rx0 = 0, ry0 = 0, regionW = geo.w;
    if (widget.zoomIso != null) {
      final c = _byIso(widget.zoomIso!);
      if (c != null) {
        double x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
        for (final poly in c.polys) {
          for (final ring in poly) {
            for (final p in ring) {
              if (p.dx < x0) x0 = p.dx;
              if (p.dy < y0) y0 = p.dy;
              if (p.dx > x1) x1 = p.dx;
              if (p.dy > y1) y1 = p.dy;
            }
          }
        }
        final cx = (x0 + x1) / 2, cy = (y0 + y1) / 2;
        regionW = (max(x1 - x0, (y1 - y0) * aspect) * 2.4).clamp(70.0, geo.w);
        final rh = regionW / aspect;
        rx0 = (cx - regionW / 2).clamp(0.0, geo.w - regionW);
        ry0 = (cy - rh / 2).clamp(0.0, geo.h - rh);
      }
    }

    return AspectRatio(
      aspectRatio: aspect,
      child: LayoutBuilder(
        builder: (ctx, cons) {
          final zs = cons.maxWidth / regionW;
          return GestureDetector(
            onTapUp: (d) {
              if (widget.onTap == null) return;
              final c = _hitTest(
                d.localPosition.dx / zs + rx0,
                d.localPosition.dy / zs + ry0,
              );
              if (c != null) widget.onTap!(c.iso, c.name);
            },
            child: CustomPaint(
              size: Size(cons.maxWidth, cons.maxHeight),
              painter: _MapPainter(
                geo,
                widget.values,
                widget.colorOverride,
                breaks,
                widget.highlightIso,
                rx0,
                ry0,
                zs,
                widget.capital,
                isLight,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final WorldGeo geo;
  final Map<String, double> values;
  final Map<String, Color>? colorOverride;
  final List<double> breaks;
  final String? highlight;
  final double rx0;
  final double ry0;
  final double zs;
  final CapitalMarker? capital;
  final bool light; // theme at build time, so a theme flip repaints
  _MapPainter(
    this.geo,
    this.values,
    this.colorOverride,
    this.breaks,
    this.highlight,
    this.rx0,
    this.ry0,
    this.zs,
    this.capital,
    this.light,
  );

  // Neutral "land" grey so countries read on the background even with no
  // data; hatched in paint() so it can't pass for the lowest class.
  final _noData = Paint()..color = Choropleth.noDataColor;
  final _border = Paint()
    ..color = isLight
        ? const Color(0x33000000) // dark hairline on the cream theme
        : const Color(0x66FFFFFF) // light hairline separates every country
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  @override
  void paint(Canvas canvas, Size size) {
    final canvasRect = Offset.zero & size;
    for (final c in geo.countries) {
      final path = Path()..fillType = PathFillType.evenOdd;
      for (final poly in c.polys) {
        for (final ring in poly) {
          if (ring.isEmpty) continue;
          // Split rings that wrap the antimeridian (Russia, Fiji): a jump of
          // half the map between neighbours would otherwise paint a streak
          // right across the world.
          path.moveTo((ring[0].dx - rx0) * zs, (ring[0].dy - ry0) * zs);
          for (int i = 1; i < ring.length; i++) {
            if ((ring[i].dx - ring[i - 1].dx).abs() > geo.w / 2) {
              path.close();
              path.moveTo((ring[i].dx - rx0) * zs, (ring[i].dy - ry0) * zs);
            } else {
              path.lineTo((ring[i].dx - rx0) * zs, (ring[i].dy - ry0) * zs);
            }
          }
          path.close();
        }
      }
      final v = values[c.iso];
      final override = colorOverride?[c.iso];
      final Paint fill;
      if (c.iso == highlight) {
        fill = Paint()..color = kAmber; // selected country pops (locator map)
      } else if (override != null) {
        fill = Paint()..color = override; // bivariate blend
      } else if (v == null || !v.isFinite) {
        fill = _noData;
      } else {
        fill = Paint()..color = Choropleth.colorFor(v, breaks);
      }
      canvas.drawPath(path, fill);
      if (identical(fill, _noData)) {
        // Hatch no-data shapes so they can't be read as the lowest class.
        final r = path.getBounds().intersect(canvasRect);
        if (r.width > 0 && r.height > 0) {
          canvas.save();
          canvas.clipPath(path);
          _paintHatch(canvas, r, spacing: 5);
          canvas.restore();
        }
      }
      canvas.drawPath(path, _border);
      if (c.iso == highlight) {
        canvas.drawPath(
          path,
          Paint()
            ..color = kText
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      }
    }
    _paintCapital(canvas, size);
  }

  /// Halo + dot + name label on the capital, like the site's CountryPanel.
  void _paintCapital(Canvas canvas, Size size) {
    final cap = capital;
    if (cap == null) return;
    final cx = (cap.x - rx0) * zs, cy = (cap.y - ry0) * zs;
    if (cx < 0 || cy < 0 || cx > size.width || cy > size.height) return;
    final r = (size.width * 0.008).clamp(2.5, 5.0);
    canvas.drawCircle(
      Offset(cx, cy),
      r * 2.2,
      Paint()..color = kBg.withValues(alpha: 0.45),
    );
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = kText);
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = kBg
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (cap.name.isEmpty) return;
    final fs = (size.width * 0.028).clamp(9.0, 13.0);
    final tp = TextPainter(
      text: TextSpan(
        text: cap.name,
        style: TextStyle(
          color: kText,
          fontSize: fs,
          fontWeight: FontWeight.w700,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 3),
            Shadow(color: Colors.black, blurRadius: 6),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // Label above the dot, nudged back inside the canvas near the edges.
    final lx = (cx - tp.width / 2).clamp(2.0, size.width - tp.width - 2);
    var ly = cy - r * 2.2 - tp.height - 2;
    if (ly < 2) ly = cy + r * 2.2 + 2;
    tp.paint(canvas, Offset(lx, ly));
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.colorOverride != colorOverride ||
      old.values != values ||
      !listEquals(old.breaks, breaks) ||
      old.light != light ||
      old.highlight != highlight ||
      old.zs != zs ||
      old.rx0 != rx0 ||
      old.ry0 != ry0 ||
      old.capital != capital;
}
