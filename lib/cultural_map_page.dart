import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'flags.dart';
import 'theme.dart';

/// Native (condensed) Inglehart–Welzel cultural map — a port of the site's
/// CulturalMap: X = self-expression values, Y = secular values, dots coloured
/// by cultural zone, anchor countries labelled, tap a dot for details.
class CulturalMapPage extends StatefulWidget {
  const CulturalMapPage({super.key});
  @override
  State<CulturalMapPage> createState() => _CulturalMapPageState();
}

// Cultural zone per ISO — same table as the site.
const _zone = <String, String>{
  'CZE': 'cat', 'KOR': 'con', 'MNG': 'con', 'MAC': 'con', 'HKG': 'con',
  'CAN': 'eng', 'UKR': 'ort', 'SVK': 'cat', 'CHL': 'lat', 'NLD': 'pro',
  'TWN': 'con', 'RUS': 'ort', 'JPN': 'con', 'SRB': 'ort', 'MEX': 'lat',
  'GBR': 'eng', 'VNM': 'con', 'ARG': 'lat', 'VEN': 'lat', 'AUS': 'eng',
  'AND': 'cat', 'NZL': 'eng', 'GTM': 'lat', 'CHN': 'con', 'NIR': 'eng',
  'THA': 'was', 'TJK': 'afi', 'DEU': 'pro', 'MYS': 'was', 'USA': 'eng',
  'PER': 'lat', 'URY': 'lat', 'KAZ': 'ort', 'BOL': 'lat', 'LBN': 'afi',
  'MAR': 'afi', 'NIC': 'lat', 'BRA': 'lat', 'IRQ': 'afi', 'COL': 'lat',
  'KEN': 'afi', 'ECU': 'lat', 'ROU': 'ort', 'GRC': 'ort', 'SGP': 'was',
  'PHL': 'lat', 'MMR': 'afi', 'CYP': 'was', 'KGZ': 'afi', 'TUN': 'afi',
  'ARM': 'ort', 'TUR': 'afi', 'PRI': 'lat', 'IRN': 'afi', 'IDN': 'afi',
  'NGA': 'afi', 'PAK': 'afi', 'BGD': 'afi', 'ZWE': 'afi', 'LBY': 'afi',
  'MDV': 'afi', 'ETH': 'afi', 'JOR': 'afi', 'EGY': 'afi',
};

// Zone label + colour — the site's ZMETA.
const _zmeta = <String, (String, Color)>{
  'con': ('Confucian', Color(0xFFE0566A)),
  'pro': ('Protestant Europe', Color(0xFF3F9AE0)),
  'cat': ('Catholic Europe', Color(0xFF4A6CD4)),
  'eng': ('English-Speaking', Color(0xFF7A5FD0)),
  'lat': ('Latin America', Color(0xFF12A596)),
  'was': ('West & South Asia', Color(0xFFE0A838)),
  'afi': ('African-Islamic', Color(0xFF4FA356)),
  'ort': ('Orthodox Europe', Color(0xFFCF57A6)),
};

// Labelled anchors, as on the site (subset that reads well on a phone).
const _anchors = {
  'JPN', 'KOR', 'CHN', 'DEU', 'NLD', 'USA', 'GBR', 'AUS', 'BRA', 'MEX',
  'ARG', 'EGY', 'NGA', 'IRN', 'TUR', 'IDN', 'RUS', 'UKR', 'GRC',
};

class _CPt {
  final String iso, name, zone;
  final double x, y;
  const _CPt(this.iso, this.name, this.zone, this.x, this.y);
}

class _CulturalMapPageState extends State<CulturalMapPage> {
  List<_CPt>? _pts;
  String? _error;
  _CPt? _sel;

  /// Zone picked in the legend — its dots stay bright, the rest fade.
  String? _zoneHi;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Future.wait(
          [fetchDataset('wvs-emancipative'), fetchDataset('wvs-secular')]);
      final em = res[0], sec = res[1];
      Map<String, Observation> latest(Dataset d) {
        final m = <String, Observation>{};
        for (final o in d.data) {
          if (o.iso.isEmpty) continue;
          final cur = m[o.iso];
          if (cur == null || o.period.compareTo(cur.period) > 0) m[o.iso] = o;
        }
        return m;
      }

      final e = latest(em), s = latest(sec);
      final pts = <_CPt>[];
      for (final iso in e.keys) {
        final so = s[iso];
        if (so == null) continue;
        pts.add(_CPt(iso, e[iso]!.entity, _zone[iso] ?? 'was', e[iso]!.value,
            so.value));
      }
      if (mounted) setState(() => _pts = pts);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map of values',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Couldn\'t load.\n$_error',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kTextDim))))
          : _pts == null
              ? Center(child: CircularProgressIndicator(color: kAmber))
              : _body(),
    );
  }

  Widget _body() {
    final pts = _pts!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('WORLD VALUES SURVEY',
            style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: kAmber)),
        const SizedBox(height: 4),
        const Text('The Inglehart–Welzel map',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, height: 1.15)),
        const SizedBox(height: 8),
        Text(
            'Every society on two axes: survival → self-expression values (→) '
            'and traditional → secular values (↑). Colours are cultural zones. '
            'Tap a dot to name it; tap a zone to pick it out.',
            style: TextStyle(fontSize: 13, color: kTextDim, height: 1.45)),
        const SizedBox(height: 14),
        AspectRatio(
          aspectRatio: 0.95,
          child: LayoutBuilder(builder: (context, box) {
            return GestureDetector(
              onTapDown: (d) => _onTap(d.localPosition, box.biggest, pts),
              child: CustomPaint(
                painter: _CulturalPainter(pts, _sel, zone: _zoneHi),
                child: const SizedBox.expand(),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        // Zone legend, right under the chart so the colours can be read off
        // without scrolling. Tapping a zone highlights its countries.
        Text('CULTURAL ZONES',
            style: TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: kTextDim)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final z in _zmeta.entries)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(
                    () => _zoneHi = _zoneHi == z.key ? null : z.key),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _zoneHi == z.key
                        ? z.value.$2.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _zoneHi == z.key ? z.value.$2 : kBorder,
                        width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: z.value.$2, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(
                          '${z.value.$1} · ${pts.where((p) => p.zone == z.key).length}',
                          style: TextStyle(
                              fontSize: 11,
                              color: _zoneHi == z.key ? kText : kTextDim,
                              fontWeight: _zoneHi == z.key
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (_sel != null)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: (_zmeta[_sel!.zone]?.$2 ?? kAmber), width: 1),
            ),
            child: Row(
              children: [
                Text(flagFromIso(_sel!.iso),
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_sel!.name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(
                          '${_zmeta[_sel!.zone]?.$1 ?? ''} · self-expression ${_sel!.x.toStringAsFixed(2)} · secular ${_sel!.y.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 11, color: kTextDim)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        Center(
          child: TextButton.icon(
            onPressed: () => launchUrl(
                Uri.parse(inAppSite('$kSiteUrl/stories/cultural-map/')),
                mode: LaunchMode.inAppBrowserView),
            icon: Icon(Icons.article_outlined, size: 18, color: kAmber),
            label: Text('Full story on the web',
                style: TextStyle(color: kAmberText, fontWeight: FontWeight.w600)),
          ),
        ),
        chartWatermark,
      ],
    );
  }

  void _onTap(Offset p, Size size, List<_CPt> pts) {
    final geo = _Geo(pts, size);
    _CPt? best;
    var bestD = 24.0; // touch radius
    for (final pt in pts) {
      final o = geo.project(pt);
      final d = (o - p).distance;
      if (d < bestD) {
        bestD = d;
        best = pt;
      }
    }
    setState(() => _sel = best);
  }
}

/// Shared projection: data range → padded canvas.
class _Geo {
  late final double minX, maxX, minY, maxY;
  final Size size;
  static const pad = 14.0;
  _Geo(List<_CPt> pts, this.size) {
    minX = pts.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    maxX = pts.map((p) => p.x).reduce((a, b) => a > b ? a : b);
    minY = pts.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    maxY = pts.map((p) => p.y).reduce((a, b) => a > b ? a : b);
  }
  Offset project(_CPt p) {
    final w = size.width - 2 * pad, h = size.height - 2 * pad;
    final x = pad + (maxX > minX ? (p.x - minX) / (maxX - minX) : 0.5) * w;
    final y = pad + (1 - (maxY > minY ? (p.y - minY) / (maxY - minY) : 0.5)) * h;
    return Offset(x, y);
  }
}

class _CulturalPainter extends CustomPainter {
  final List<_CPt> pts;
  final _CPt? sel;
  final String? zone;
  _CulturalPainter(this.pts, this.sel, {this.zone});

  @override
  void paint(Canvas canvas, Size size) {
    final geo = _Geo(pts, size);
    // frame + axis hints
    final border = Paint()
      ..color = kBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
        border);
    // Labels and axis captions must not overlap: each placed box is kept and
    // later labels try the other sides of their dot, or are left out (a tap
    // on the dot still names it). IDN and IRN used to print as one "IDRN".
    final taken = <Rect>[];
    taken.add(_axisText(canvas, 'self-expression →',
        Offset(size.width - 8, size.height - 6),
        alignRight: true));
    taken.add(_axisText(canvas, '↑ secular', const Offset(8, 14)));

    for (final p in pts) {
      final o = geo.project(p);
      final c = _zmeta[p.zone]?.$2 ?? kTextDim;
      final isSel = identical(p, sel);
      final faded = zone != null && p.zone != zone && !isSel;
      canvas.drawCircle(
          o,
          isSel ? 7 : 4.5,
          Paint()
            ..color = c.withValues(alpha: isSel ? 1 : (faded ? 0.18 : 0.8)));
      if (isSel) {
        canvas.drawCircle(
            o,
            9,
            Paint()
              ..color = c
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6);
      }
    }

    // The selected dot is labelled first, then the anchors (all of a
    // highlighted zone's countries when one is picked), left to right.
    final labelled = [
      ?sel,
      for (final p in pts)
        if (!identical(p, sel) &&
            (zone != null ? p.zone == zone : _anchors.contains(p.iso)))
          p,
    ];
    final bounds = Offset.zero & size;
    for (final p in labelled) {
      final o = geo.project(p);
      final isSel = identical(p, sel);
      final tp = TextPainter(
        text: TextSpan(
            text: p.iso,
            style: TextStyle(
                fontSize: isSel ? 10 : 8.5,
                fontWeight: FontWeight.w700,
                color: kText.withValues(alpha: isSel ? 1 : 0.85))),
        textDirection: TextDirection.ltr,
      )..layout();
      final w = tp.width, h = tp.height;
      final r = isSel ? 9.0 : 5.0;
      final candidates = [
        Offset(o.dx + r, o.dy - h - 1), // up-right (the old spot)
        Offset(o.dx + r, o.dy + 1), // down-right
        Offset(o.dx - r - w, o.dy - h - 1), // up-left
        Offset(o.dx - r - w, o.dy + 1), // down-left
        Offset(o.dx - w / 2, o.dy - r - h), // above
        Offset(o.dx - w / 2, o.dy + r), // below
      ];
      Rect? spot;
      for (final at in candidates) {
        final rect = (at & Size(w, h)).inflate(1);
        if (!bounds.contains(rect.topLeft) ||
            !bounds.contains(rect.bottomRight)) {
          continue;
        }
        if (taken.any((t) => t.overlaps(rect))) continue;
        spot = rect;
        break;
      }
      // The selected label always shows — at its first in-frame spot.
      spot ??= isSel ? (candidates.first & Size(w, h)).inflate(1) : null;
      if (spot == null) continue;
      taken.add(spot);
      if (isSel) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(spot.inflate(1), const Radius.circular(3)),
            Paint()..color = kBg.withValues(alpha: 0.85));
      }
      tp.paint(canvas, spot.topLeft + const Offset(1, 1));
    }
  }

  Rect _axisText(Canvas canvas, String s, Offset at, {bool alignRight = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: kTextDim)),
      textDirection: TextDirection.ltr,
    )..layout();
    final topLeft = alignRight ? at - Offset(tp.width, tp.height) : at - Offset(0, tp.height);
    tp.paint(canvas, topLeft);
    return topLeft & tp.size;
  }

  @override
  bool shouldRepaint(_CulturalPainter old) =>
      old.pts != pts || old.sel != sel || old.zone != zone;
}

/// Compact, non-interactive cultural map for the Polls hero — same dots and
/// zone colours, no labels except a handful of anchors; tap opens the page.
class MiniCulturalMap extends StatefulWidget {
  const MiniCulturalMap({super.key});
  @override
  State<MiniCulturalMap> createState() => _MiniCulturalMapState();
}

class _MiniCulturalMapState extends State<MiniCulturalMap> {
  List<_CPt>? _pts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Future.wait(
          [fetchDataset('wvs-emancipative'), fetchDataset('wvs-secular')]);
      Map<String, Observation> latest(Dataset d) {
        final m = <String, Observation>{};
        for (final o in d.data) {
          if (o.iso.isEmpty) continue;
          final cur = m[o.iso];
          if (cur == null || o.period.compareTo(cur.period) > 0) m[o.iso] = o;
        }
        return m;
      }

      final e = latest(res[0]), s = latest(res[1]);
      final pts = <_CPt>[];
      for (final iso in e.keys) {
        final so = s[iso];
        if (so == null) continue;
        pts.add(_CPt(iso, e[iso]!.entity, _zone[iso] ?? 'was', e[iso]!.value,
            so.value));
      }
      if (mounted) setState(() => _pts = pts);
    } catch (_) {
      // hero is decorative
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pts == null) return const SizedBox(height: 170);
    return SizedBox(
      height: 170,
      width: double.infinity,
      child: CustomPaint(painter: _CulturalPainter(_pts!, null)),
    );
  }
}
