import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'api.dart';
import 'catalog_store.dart';
import 'palette.dart';
import 'theme.dart';
import 'widgets/chart_rules.dart' show niceTicks, yDomain;
import 'widgets/region_legend.dart';
import 'widgets/search_sheet.dart';
import 'usage.dart';

/// Gapminder-style animated bubble chart — a native port of the site's
/// BubbleChart: three indicators merged on iso+year (X, Y, bubble size),
/// coloured by region, played over the years. The site's signature view.
class BubblePage extends StatefulWidget {
  const BubblePage({super.key});
  @override
  State<BubblePage> createState() => _BubblePageState();
}

class _Bubble {
  final String iso, name, region;
  final double x, y, s;
  const _Bubble(this.iso, this.name, this.region, this.x, this.y, this.s);
}

class _BubblePageState extends State<BubblePage> with UsageScreen<BubblePage> {
  @override
  String get usageScreenName => 'bubbles';

  // sensible defaults, same as the site
  String _xSlug = 'gapminder-income';
  String _ySlug = 'gapminder-life-expectancy';
  String _sSlug = 'gapminder-population';
  bool _logX = true;

  Dataset? _xd, _yd, _sd;
  // merged bubbles per year (only years with at least one country)
  Map<String, List<_Bubble>> _frames = {};
  List<String> _years = [];
  int _yi = 0;
  bool _playing = false;
  Timer? _timer;
  String? _error;
  String? _selected; // iso of the tapped bubble, followed across years

  @override
  void initState() {
    super.initState();
    usageFirstChart();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _selected = null;
      _xd = _yd = _sd = null;
    });
    try {
      final res = await Future.wait([
        fetchDataset(_xSlug),
        fetchDataset(_ySlug),
        fetchDataset(_sSlug),
      ]);
      final frames = _merge(res[0], res[1], res[2]);
      setState(() {
        _xd = res[0];
        _yd = res[1];
        _sd = res[2];
        _frames = frames;
        _years = frames.keys.toList()..sort();
        _yi = _years.isEmpty ? 0 : _years.length - 1;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  /// Joins the three datasets on iso + year; aggregates (no iso) are skipped.
  static Map<String, List<_Bubble>> _merge(Dataset xd, Dataset yd, Dataset sd) {
    Map<String, Observation> index(Dataset d) => {
      for (final o in d.data)
        if (o.iso.isNotEmpty) '${o.period}|${o.iso}': o,
    };
    final ym = index(yd), sm = index(sd);
    final frames = <String, List<_Bubble>>{};
    for (final xo in xd.data) {
      if (xo.iso.isEmpty) continue;
      final key = '${xo.period}|${xo.iso}';
      final yo = ym[key], so = sm[key];
      if (yo == null || so == null) continue;
      (frames[xo.period] ??= []).add(
        _Bubble(xo.iso, xo.entity, xo.group, xo.value, yo.value, so.value),
      );
    }
    return frames;
  }

  void _togglePlay() {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }
    if (_years.isEmpty) return;
    if (_yi >= _years.length - 1) _yi = 0; // restart from the beginning
    setState(() => _playing = true);
    _timer = Timer.periodic(const Duration(milliseconds: 550), (t) {
      if (_yi >= _years.length - 1) {
        t.cancel();
        setState(() => _playing = false);
      } else {
        setState(() => _yi++);
      }
    });
  }

  void _pick(String which) {
    showSearchSheet<CatalogEntry>(
      context,
      title: 'Pick indicator ($which)',
      items: catalog,
      label: (e) => e.title,
      sub: (e) => e.source,
      onPick: (e) {
        usageContentDataset(e.slug);
        _timer?.cancel();
        setState(() {
          _playing = false;
          if (which == 'X') _xSlug = e.slug;
          if (which == 'Y') _ySlug = e.slug;
          if (which == 'size') _sSlug = e.slug;
        });
        _load();
      },
    );
  }

  String _unit(Dataset d, String slug) =>
      d.unit.isNotEmpty ? d.unit : (catalogBySlug[slug]?.unit ?? '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Animated bubbles',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Couldn\'t load.\n$_error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextDim),
                ),
              ),
            )
          : (_xd == null || _yd == null || _sd == null)
          ? Center(child: CircularProgressIndicator(color: kAmber))
          : _body(),
    );
  }

  Widget _body() {
    if (_years.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'These three indicators share no common years.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextDim),
          ),
        ),
      );
    }
    final pts = _frames[_years[_yi]]!;
    // fixed domains across ALL years so bubbles don't jump between frames
    final all = _frames.values.expand((f) => f).toList();
    final xAxis = _Axis.fit([for (final b in all) b.x], logScale: _logX);
    final yAxis = _Axis.fit([for (final b in all) b.y]);
    final maxS = all.map((b) => b.s).fold(0.0, max);

    final xTitle = catalogBySlug[_xSlug]?.title ?? _xSlug;
    final yTitle = catalogBySlug[_ySlug]?.title ?? _ySlug;
    final sTitle = catalogBySlug[_sSlug]?.title ?? _sSlug;
    final xUnit = _unit(_xd!, _xSlug), yUnit = _unit(_yd!, _ySlug);
    final sUnit = _unit(_sd!, _sSlug);
    String withUnit(String t, String u) => u.isEmpty ? t : '$t ($u)';
    final axisStyle = TextStyle(fontSize: 11, color: kTextDim);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // indicator pickers
        _pickRow('X →', xTitle, () => _pick('X')),
        _pickRow('Y ↑', yTitle, () => _pick('Y')),
        _pickRow('Size', sTitle, () => _pick('size')),
        Row(
          children: [
            Checkbox(
              value: _logX,
              onChanged: (v) => setState(() => _logX = v ?? false),
              activeColor: kAmber,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Text('log X', style: TextStyle(fontSize: 13, color: kText)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '↑ ${withUnit(yTitle, yUnit)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: axisStyle,
        ),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 1.05,
          child: LayoutBuilder(
            builder: (context, c) {
              final plot = _Plot(c.biggest, xAxis, yAxis, maxS);
              final sel = pts.where((b) => b.iso == _selected).firstOrNull;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                // tap a bubble to select it; tap empty space to dismiss
                onTapUp: (d) => setState(
                  () => _selected = plot.hit(pts, d.localPosition)?.iso,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BubblePainter(plot, pts, sel),
                      ),
                    ),
                    if (sel != null)
                      _tooltip(plot, sel, [
                        (xTitle, sel.x, xUnit),
                        (yTitle, sel.y, yUnit),
                        (sTitle, sel.s, sUnit),
                      ]),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${withUnit(xTitle, xUnit)}${xAxis.isLog ? ', log scale' : ''} →',
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: axisStyle,
        ),
        RegionLegend(regions: pts.map((p) => p.region)),
        const SizedBox(height: 12),
        // player: play button + year slider + big year label
        Row(
          children: [
            InkWell(
              onTap: _togglePlay,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: kAmber,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _playing ? Icons.pause : Icons.play_arrow,
                      size: 18,
                      color: kBg,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _playing ? 'Pause' : 'Play',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: kBg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: _yi.toDouble(),
                min: 0,
                max: (_years.length - 1).toDouble(),
                divisions: max(1, _years.length - 1),
                activeColor: kAmber,
                onChanged: (v) {
                  _timer?.cancel();
                  setState(() {
                    _playing = false;
                    _yi = v.round();
                  });
                },
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                _years[_yi],
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kAmber,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${pts.length} countries · bubble size = $sTitle · '
          'tap a bubble for details',
          style: TextStyle(fontSize: 11, color: kTextDim),
        ),
        chartWatermark,
      ],
    );
  }

  /// Small card next to the selected bubble: name, region and its values.
  Widget _tooltip(_Plot plot, _Bubble b, List<(String, double, String)> rows) {
    const w = 200.0;
    final p = plot.at(b), r = plot.radius(b), h = plot.size.height;
    final left = (p.dx - w / 2)
        .clamp(0.0, max(0.0, plot.size.width - w))
        .toDouble();
    final above = p.dy > h / 2; // keep the card inside the plot
    return Positioned(
      left: left,
      width: w,
      top: above ? null : p.dy + r + 6,
      bottom: above ? h - (p.dy - r - 6) : null,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: kBgCard,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: colorFor(b.region),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kText,
                      ),
                    ),
                  ),
                ],
              ),
              if (b.region.isNotEmpty)
                Text(b.region, style: TextStyle(fontSize: 10, color: kTextDim)),
              const SizedBox(height: 4),
              for (final (title, v, unit) in rows)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$title: ',
                        style: TextStyle(color: kTextDim),
                      ),
                      TextSpan(
                        text:
                            '${formatValue(v)}${unit.isEmpty ? '' : ' $unit'}',
                        style: TextStyle(
                          color: kText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickRow(String axis, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                axis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kTextDim,
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.unfold_more, size: 18, color: kTextDim),
          ],
        ),
      ),
    );
  }
}

/// One axis: a domain fitted to the data (8% padding, no forced zero) and its
/// round ticks. Log scale only when every value is above 0.
class _Axis {
  final double lo, hi;
  final bool isLog;
  const _Axis(this.lo, this.hi, this.isLog);

  factory _Axis.fit(List<double> values, {bool logScale = false}) {
    final v = values.where((x) => x.isFinite).toList();
    if (v.isEmpty) return const _Axis(0, 1, false);
    if (logScale && v.every((x) => x > 0)) {
      // pad in log space so both ends get the same visual margin
      final (a, b) = yDomain([for (final x in v) log(x)]);
      return _Axis(exp(a), exp(b), true);
    }
    var (a, b) = yDomain(v);
    // don't pad across zero: data that stays >= 0 starts at 0 at the lowest
    final dlo = v.reduce(min), dhi = v.reduce(max);
    if (dlo >= 0 && a < 0) a = 0;
    if (dhi <= 0 && b > 0) b = 0;
    return _Axis(a, b, false);
  }

  /// 0..1 position of [v] along the axis.
  double t(double v) => isLog
      ? (log(max(v, lo)) - log(lo)) / (log(hi) - log(lo))
      : (v - lo) / (hi - lo);

  List<double> get ticks {
    if (!isLog) return niceTicks(lo, hi);
    // log axis: round ratios — powers of ten (1k, 10k, 100k), with 2 and 5
    // in between when the range spans less than two decades
    final e0 = (log(lo) / ln10).floor(), e1 = (log(hi) / ln10).ceil();
    final decades = log(hi / lo) / ln10;
    final mults = decades < 2 ? const [1, 2, 5] : const [1];
    final every = decades > 6 ? 2 : 1;
    final out = <double>[
      for (var e = e0; e <= e1; e++)
        if (e % every == 0)
          for (final m in mults)
            if (m * pow(10, e) >= lo && m * pow(10, e) <= hi)
              (m * pow(10, e)).toDouble(),
    ];
    return out.length >= 2 ? out : niceTicks(lo, hi);
  }
}

/// "1.0k" → "1k", "2.50" → "2.5": formatValue without trailing zeros.
String _tickLabel(double v) => formatValue(v)
    .replaceFirstMapped(
      RegExp(r'(\.\d*?)0+([kMBT]?)$'),
      (m) => '${m[1]}${m[2]}',
    )
    .replaceFirst(RegExp(r'\.(?=[kMBT]?$)'), '');

/// Plot geometry shared by the painter and tap hit-testing.
class _Plot {
  static const padL = 38.0, padR = 10.0, padT = 8.0, padB = 20.0;
  final Size size;
  final _Axis x, y;
  final double maxS;
  _Plot(this.size, this.x, this.y, this.maxS);

  Rect get area =>
      Rect.fromLTRB(padL, padT, size.width - padR, size.height - padB);

  double px(double v) => area.left + x.t(v) * area.width;
  double py(double v) => area.bottom - y.t(v) * area.height;
  Offset at(_Bubble b) => Offset(px(b.x), py(b.y));
  double radius(_Bubble b) =>
      3 + 22 * sqrt((b.s / (maxS <= 0 ? 1 : maxS)).clamp(0, 1));

  /// The bubble under [p] (nearest centre, with a few points of slack for
  /// small bubbles), or null for empty space.
  _Bubble? hit(List<_Bubble> pts, Offset p) {
    _Bubble? best;
    var bestD = double.infinity;
    for (final b in pts) {
      final d = (at(b) - p).distance;
      if (d <= radius(b) + 6 && d < bestD) {
        best = b;
        bestD = d;
      }
    }
    return best;
  }
}

class _BubblePainter extends CustomPainter {
  final _Plot plot;
  final List<_Bubble> pts;
  final _Bubble? selected;
  _BubblePainter(this.plot, this.pts, this.selected);

  void _text(Canvas canvas, String s, Offset Function(Size) place) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontSize: 10, color: kTextDim),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, place(tp.size));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final a = plot.area;
    final grid = Paint()
      ..color = kBorder
      ..strokeWidth = 0.5;
    final zero = Paint()
      ..color = kTextDim.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    // Y gridlines + labels
    for (final v in plot.y.ticks) {
      final y = plot.py(v);
      canvas.drawLine(
        Offset(a.left, y),
        Offset(a.right, y),
        v == 0 ? zero : grid,
      );
      _text(
        canvas,
        _tickLabel(v),
        (s) => Offset(a.left - 5 - s.width, y - s.height / 2),
      );
    }
    // X gridlines + labels
    for (final v in plot.x.ticks) {
      final x = plot.px(v);
      canvas.drawLine(
        Offset(x, a.top),
        Offset(x, a.bottom),
        v == 0 ? zero : grid,
      );
      _text(
        canvas,
        _tickLabel(v),
        (s) => Offset(
          (x - s.width / 2)
              .clamp(0.0, max(0.0, size.width - s.width))
              .toDouble(),
          a.bottom + 4,
        ),
      );
    }
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(a.left, 0, size.width, a.bottom));
    // bubbles: bigger first so small ones stay visible on top
    final sorted = [...pts]..sort((p, q) => q.s.compareTo(p.s));
    final rim = Paint()
      ..color = kBg.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (final b in sorted) {
      final c = plot.at(b), r = plot.radius(b);
      final fill = colorFor(
        b.region,
      ).withValues(alpha: selected == null || selected == b ? 0.72 : 0.35);
      canvas.drawCircle(c, r, Paint()..color = fill);
      canvas.drawCircle(c, r, rim);
    }
    if (selected case final s?) {
      canvas.drawCircle(
        plot.at(s),
        plot.radius(s),
        Paint()
          ..color = kText
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
    canvas.restore();
  }

  // the frame list, selection and geometry are rebuilt on every change
  @override
  bool shouldRepaint(_BubblePainter old) => true;
}
