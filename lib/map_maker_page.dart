import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'api.dart';
import 'catalog_store.dart';
import 'theme.dart';
import 'widgets/brand_footer.dart';
import 'widgets/choropleth.dart' show WorldGeo, GeoCountry, loadWorldGeo;
import 'widgets/load_error.dart';
import 'widgets/search_sheet.dart';
import 'usage.dart';

/// Map maker (Edu): a poster map in a handful of named colour classes, the
/// kind that travels on social media — but built from one of our indicators,
/// with its source and year printed on it.
///
/// Testers asked for it (R10, 23 Oct 2026) after an "Amazing Maps" picture of
/// European hospitality. That picture names no source; ours always does.
/// It is also a lesson in itself: change the classes or the colours and the
/// same numbers tell a different story.
class MapMakerPage extends StatefulWidget {
  const MapMakerPage({super.key});

  @override
  State<MapMakerPage> createState() => _MapMakerPageState();
}

/// A region as a rectangle in the app's map space (equirectangular, 1000×500:
/// x = (lon + 180) / 360 · 1000, y = (90 − lat) / 180 · 500).
class _Region {
  final String name;
  final Rect rect;
  const _Region(this.name, this.rect);
}

const _regions = [
  _Region('World', Rect.fromLTRB(0, 25, 1000, 417)),
  _Region('Europe', Rect.fromLTRB(431, 50, 625, 156)), // 25°W–45°E, 34°–72°N
  _Region('Africa', Rect.fromLTRB(444, 144, 653, 350)), // 20°W–55°E, 36°S–38°N
  _Region('Asia', Rect.fromLTRB(569, 83, 917, 283)), // 25°–150°E, 12°S–60°N
  _Region('Americas', Rect.fromLTRB(28, 50, 417, 408)), // 170°–30°W, 57°S–72°N
  _Region('Latin America', Rect.fromLTRB(167, 158, 417, 408)), // 120°–30°W, 57°S–33°N
];

/// Five colours from low to high; three or four classes take an even subset.
class _Palette {
  final String name;
  final List<Color> light; // on a white poster
  final List<Color> dark; // on a dark poster
  const _Palette(this.name, this.light, this.dark);
}

const _palettes = [
  _Palette('Red–blue', [
    Color(0xFFC62828), Color(0xFFF4A261), Color(0xFFE6E1D3), Color(0xFF8EC1E3), Color(0xFF1F5FAD),
  ], [
    Color(0xFFE5484D), Color(0xFFF4A261), Color(0xFF6B7078), Color(0xFF7FB6E0), Color(0xFF3B82F6),
  ]),
  _Palette('Amber', [
    Color(0xFFFFF0C2), Color(0xFFFFD166), Color(0xFFF2A900), Color(0xFFC77700), Color(0xFF7A4100),
  ], [
    Color(0xFF4A3200), Color(0xFF8A5A00), Color(0xFFC98400), Color(0xFFF2A900), Color(0xFFFFD45C),
  ]),
  _Palette('Viridis', [
    Color(0xFF440154), Color(0xFF3B528B), Color(0xFF21918C), Color(0xFF5EC962), Color(0xFFFDE725),
  ], [
    Color(0xFF440154), Color(0xFF3B528B), Color(0xFF21918C), Color(0xFF5EC962), Color(0xFFFDE725),
  ]),
];

const _formats = <(String, double)>[
  ('Square', 1.0), // 1080 × 1080
  ('Portrait', 4 / 5), // 1080 × 1350
  ('Story', 9 / 16), // 1080 × 1920
];

/// The poster is laid out at this logical width and exported at 3× = 1080 px.
const _posterW = 360.0;

class _MapMakerPageState extends State<MapMakerPage> with UsageScreen<MapMakerPage> {
  @override
  String get usageScreenName => 'map_maker';

  CatalogEntry? _entry;
  Dataset? _ds;
  Object? _error;
  WorldGeo? _geo;

  int _region = 1; // Europe
  int _classes = 4;
  int _palette = 0;
  bool _reverse = false;
  bool _darkPoster = false;
  int _format = 0;
  final _title = TextEditingController();
  List<TextEditingController> _labels = [];
  final _boundary = GlobalKey();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    loadWorldGeo().then((g) {
      if (mounted) setState(() => _geo = g);
    });
    // A survey question reads like the posters testers showed; fall back to
    // happiness, then to whatever the catalogue starts with.
    final bySlug = catalogBySlug;
    _pick(bySlug['ess-trust-people'] ?? bySlug['whr-happiness'] ?? catalog.first);
  }

  @override
  void dispose() {
    _title.dispose();
    for (final c in _labels) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(CatalogEntry e) async {
    setState(() {
      _entry = e;
      _ds = null;
      _error = null;
      _title.text = e.title;
    });
    try {
      final ds = await fetchDataset(e.slug);
      if (!mounted || _entry?.slug != e.slug) return;
      setState(() => _ds = ds);
      _resetLabels();
    } catch (err) {
      if (mounted) setState(() => _error = err);
    }
  }

  /// Latest value per country, and the years they come from.
  ({Map<String, double> values, String period}) get _latest {
    final ds = _ds;
    if (ds == null) return (values: <String, double>{}, period: '');
    final best = <String, Observation>{};
    for (final o in ds.data) {
      if (o.iso.isEmpty || !o.value.isFinite) continue;
      final b = best[o.iso];
      if (b == null || o.period.compareTo(b.period) > 0) best[o.iso] = o;
    }
    final years = best.values.map((o) => o.period).toSet().toList()..sort();
    final period = years.isEmpty
        ? ''
        : years.length == 1
            ? years.first
            : '${years.first}–${years.last}, latest per country';
    return (values: {for (final e in best.entries) e.key: e.value.value}, period: period);
  }

  /// Countries whose middle falls inside the region.
  Set<String> _inRegion(Rect r) {
    final geo = _geo;
    if (geo == null) return {};
    final out = <String>{};
    for (final c in geo.countries) {
      double x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
      for (final poly in c.polys) {
        if (poly.isEmpty) continue;
        for (final p in poly[0]) {
          x0 = min(x0, p.dx);
          y0 = min(y0, p.dy);
          x1 = max(x1, p.dx);
          y1 = max(y1, p.dy);
        }
      }
      // Russia spans the map; it belongs to Europe's poster as well as Asia's.
      final cx = c.iso == 'RUS' ? 560.0 : (x0 + x1) / 2;
      final cy = c.iso == 'RUS' ? 70.0 : (y0 + y1) / 2;
      if (r.contains(Offset(cx, cy))) out.add(c.iso);
    }
    return out;
  }

  /// Quantile breaks over the region's countries: each class holds about the
  /// same number of countries. Returns the k − 1 inner thresholds.
  List<double> _breaks(Map<String, double> vals, Set<String> region) {
    final v = [
      for (final e in vals.entries)
        if (region.contains(e.key)) e.value
    ]..sort();
    if (v.isEmpty) return [];
    return [
      for (var i = 1; i < _classes; i++) v[min(v.length - 1, (v.length * i / _classes).floor())]
    ];
  }

  String _fmt(double x) {
    final u = _entry?.unit ?? '';
    final s = formatValue(x);
    return u == '%' ? '$s%' : s;
  }

  void _resetLabels() {
    final l = _latest;
    final b = _breaks(l.values, _inRegion(_regions[_region].rect));
    final names = <String>[];
    if (b.length == _classes - 1) {
      for (var i = 0; i < _classes; i++) {
        if (i == 0) {
          names.add('Under ${_fmt(b[0])}');
        } else if (i == _classes - 1) {
          names.add('${_fmt(b[i - 1])} and over');
        } else {
          names.add('${_fmt(b[i - 1])}–${_fmt(b[i])}');
        }
      }
    }
    for (final c in _labels) {
      c.dispose();
    }
    setState(() => _labels = [for (final n in names) TextEditingController(text: n)]);
  }

  List<Color> get _colors {
    final p = _palettes[_palette];
    final all = _darkPoster ? p.dark : p.light;
    final idx = switch (_classes) { 3 => [0, 2, 4], 4 => [0, 1, 3, 4], _ => [0, 1, 2, 3, 4] };
    final c = [for (final i in idx) all[i]];
    return _reverse ? c.reversed.toList() : c;
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final rb = _boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await rb.toImage(pixelRatio: 1080 / _posterW);
      final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bulldozer_map.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: '${_title.text.trim()} — made with BullDozer · azenha.ai/bulldozer',
      ));
      usageFeature('map_shared');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Couldn't create the image.")));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final geo = _geo;
    final latest = _latest;
    final region = _regions[_region];
    final members = _inRegion(region.rect);
    final breaks = _breaks(latest.values, members);
    final colors = _colors;

    final fills = <String, Color>{};
    if (breaks.length == _classes - 1) {
      for (final e in latest.values.entries) {
        var k = 0;
        while (k < breaks.length && e.value >= breaks[k]) {
          k++;
        }
        fills[e.key] = colors[k];
      }
    }

    final poster = (geo == null || _ds == null)
        ? null
        : _Poster(
            geo: geo,
            region: region.rect,
            fills: fills,
            colors: colors,
            labels: [for (final c in _labels) c.text],
            title: _title.text,
            footer: 'Source: ${_entry?.source ?? ''}${latest.period.isEmpty ? '' : ' · ${latest.period}'}',
            dark: _darkPoster,
            aspect: _formats[_format].$2,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map maker', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // The poster is laid out at a fixed width so the export looks
              // the same on every phone; the preview only scales it.
              if (_error != null)
                SizedBox(
                    height: 320,
                    child: LoadError(
                        error: _error!, what: 'this indicator', onRetry: () => _pick(_entry!)))
              else if (poster == null)
                SizedBox(height: 320, child: Center(child: CircularProgressIndicator(color: kAmber)))
              else
                FittedBox(
                  child: RepaintBoundary(key: _boundary, child: poster),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: poster == null || _busy ? null : _share,
                style: FilledButton.styleFrom(backgroundColor: kAmber, foregroundColor: kBg),
                icon: _busy
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.ios_share),
                label: const Text('Share image', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 18),
              _label('Indicator'),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: Text(_entry?.title ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_entry?.source ?? '', style: TextStyle(color: kTextDim, fontSize: 12)),
                  trailing: const Icon(Icons.unfold_more),
                  onTap: () => showSearchSheet<CatalogEntry>(
                    context,
                    title: 'Choose an indicator',
                    items: catalog,
                    label: (e) => e.title,
                    sub: (e) => e.source,
                    onPick: (e) {
                      usageContentDataset(e.slug);
                      _pick(e);
                    },
                  ),
                ),
              ),
              _label('Title'),
              TextField(
                controller: _title,
                maxLength: 90,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    hintText: 'A question, e.g. "Can most people be trusted?"',
                    border: OutlineInputBorder(),
                    counterText: ''),
              ),
              _label('Region'),
              _chips([for (final r in _regions) r.name], _region, (i) {
                setState(() => _region = i);
                _resetLabels();
              }),
              _label('Classes'),
              _chips(['3', '4', '5'], _classes - 3, (i) {
                setState(() => _classes = i + 3);
                _resetLabels();
              }),
              _label('Colours'),
              _chips([for (final p in _palettes) p.name], _palette,
                  (i) => setState(() => _palette = i)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reverse colours'),
                subtitle: Text('When a high value is the bad news', style: TextStyle(color: kTextDim, fontSize: 12)),
                value: _reverse,
                onChanged: (v) => setState(() => _reverse = v),
              ),
              _label('Background'),
              _chips(['Light', 'Dark'], _darkPoster ? 1 : 0, (i) => setState(() => _darkPoster = i == 1)),
              _label('Format'),
              _chips([for (final f in _formats) f.$1], _format, (i) => setState(() => _format = i)),
              Row(children: [
                Expanded(child: _label('Class names')),
                TextButton(onPressed: _resetLabels, child: const Text('Reset to numbers')),
              ]),
              for (var i = 0; i < _labels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                            color: i < colors.length ? colors[i] : null,
                            borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _labels[i],
                        maxLength: 24,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                            isDense: true, border: OutlineInputBorder(), counterText: ''),
                      ),
                    ),
                  ]),
                ),
              const SizedBox(height: 6),
              Text(
                'Classes split the countries in the region into groups of about the same size. '
                'Rename them in words ("Almost never" … "Almost always") — the numbers stay the source\'s.',
                style: TextStyle(color: kTextDim, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 0, 6),
        child: Text(s.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: kAmber)),
      );

  Widget _chips(List<String> items, int selected, void Function(int) onTap) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < items.length; i++)
            ChoiceChip(label: Text(items[i]), selected: i == selected, onSelected: (_) => onTap(i)),
        ],
      );
}

/// The exported picture. Its own fixed colours, not the app theme's, so the
/// image is the same whichever theme the phone is in.
class _Poster extends StatelessWidget {
  final WorldGeo geo;
  final Rect region;
  final Map<String, Color> fills;
  final List<Color> colors;
  final List<String> labels;
  final String title;
  final String footer;
  final bool dark;
  final double aspect;

  const _Poster({
    required this.geo,
    required this.region,
    required this.fills,
    required this.colors,
    required this.labels,
    required this.title,
    required this.footer,
    required this.dark,
    required this.aspect,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF0E0F11) : const Color(0xFFFFFFFF);
    final ink = dark ? const Color(0xFFF2F3F5) : const Color(0xFF15171A);
    final dim = dark ? const Color(0xFF9AA1A9) : const Color(0xFF5F6670);
    final t = title.trim().isEmpty ? ' ' : title.trim();
    final titleSize = t.length > 60 ? 19.0 : t.length > 36 ? 23.0 : 27.0;
    return SizedBox(
      width: _posterW,
      height: _posterW / aspect,
      child: ColoredBox(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: ink, fontSize: titleSize, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.3)),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < colors.length; i++)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                        color: colors[i],
                        alignment: Alignment.center,
                        child: Text(
                          i < labels.length ? labels[i].toUpperCase() : '',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                              color: colors[i].computeLuminance() > 0.45 ? const Color(0xFF15171A) : Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              height: 1.1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: CustomPaint(
                  painter: _PosterMapPainter(geo, region, fills,
                      dark ? const Color(0xFF2A2F36) : const Color(0xFFE3E1DC),
                      dark ? const Color(0x55FFFFFF) : const Color(0xFFFFFFFF)),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  brandMark(16),
                  const SizedBox(width: 5),
                  Text('BullDozer', style: TextStyle(color: ink, fontSize: 10, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(footer,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: dim, fontSize: 7.5, height: 1.25)),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: BrandFooter(color: dark ? const Color(0xFFFFB000) : const Color(0xFF8F5E00), dim: dim, fontSize: 7.5, align: MainAxisAlignment.end),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterMapPainter extends CustomPainter {
  final WorldGeo geo;
  final Rect region;
  final Map<String, Color> fills;
  final Color noData;
  final Color border;
  _PosterMapPainter(this.geo, this.region, this.fills, this.noData, this.border);

  @override
  void paint(Canvas canvas, Size size) {
    // Fit the region into the box, keep its proportions, centre it.
    final s = min(size.width / region.width, size.height / region.height);
    final ox = (size.width - region.width * s) / 2 - region.left * s;
    final oy = (size.height - region.height * s) / 2 - region.top * s;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final stroke = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (final GeoCountry c in geo.countries) {
      final path = Path()..fillType = PathFillType.evenOdd;
      for (final poly in c.polys) {
        for (final ring in poly) {
          if (ring.isEmpty) continue;
          path.moveTo(ring[0].dx * s + ox, ring[0].dy * s + oy);
          for (var i = 1; i < ring.length; i++) {
            // Rings that wrap the antimeridian would streak across the map.
            if ((ring[i].dx - ring[i - 1].dx).abs() > geo.w / 2) {
              path.close();
              path.moveTo(ring[i].dx * s + ox, ring[i].dy * s + oy);
            } else {
              path.lineTo(ring[i].dx * s + ox, ring[i].dy * s + oy);
            }
          }
          path.close();
        }
      }
      canvas.drawPath(path, Paint()..color = fills[c.iso] ?? noData);
      canvas.drawPath(path, stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PosterMapPainter o) =>
      o.region != region || o.fills != fills || o.noData != noData;
}
