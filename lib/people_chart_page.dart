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
import 'widgets/load_error.dart';
import 'widgets/search_sheet.dart';

/// People chart maker (Edu): every country as a column of 100 small figures,
/// the "Times Voter Trends" look testers showed (R14, 28 Oct 2026).
///
/// That chart splits individual voters by education. We publish one figure
/// per country, not respondents, so ours compares countries: one share-of-
/// people question, the broad cause groups of death (which add up to 100%),
/// or a table the user types in. Every picture built from our data carries
/// its source and year.
class PeopleChartPage extends StatefulWidget {
  const PeopleChartPage({super.key});

  @override
  State<PeopleChartPage> createState() => _PeopleChartPageState();
}

enum _Mode { question, causes, own }

/// Percentage series that are not a share of people.
const _notPeople = {'bigmac-usd-valuation', 'owid-renewables', 'imf-world-gdp-share'};

bool _isShareOfPeople(CatalogEntry e) =>
    e.unit == '%' && !_notPeople.contains(e.slug) && !e.title.contains('(historical)');

/// What the 100 figures stand for.
String _noun(String slug) => slug.startsWith('who-ghe-')
    ? 'deaths'
    : slug == 'owid-child-mortality'
        ? 'children born'
        : slug == 'imf-unemployment'
            ? 'people in the labour force'
            : 'people';

/// WHO's broad cause groups for 2021; together they are every death. The
/// fourth (other pandemic-related deaths) is small but real — Chad 1.7% —
/// and without it the three were stretched to fill the hundred.
const _causeSlugs = ['who-ghe-communicable', 'who-ghe-ncd', 'who-ghe-injuries', 'who-ghe-pandemic-other'];
const _causeNames = [
  'Infections, maternal & nutrition',
  'Noncommunicable diseases',
  'Injuries',
  'Other pandemic-related',
];

const _inks = [
  Color(0xFFE0A33A), // amber
  Color(0xFF3FA796), // teal
  Color(0xFF8E7FD8), // violet
  Color(0xFFE5484D), // red
];

const _formats = <(String, double)>[
  ('Square', 1.0),
  ('Portrait', 4 / 5),
  ('Story', 9 / 16),
];

const _posterW = 360.0;

/// Whole figures out of 100 for shares that should fill the column (largest
/// remainder, so the counts always add up to exactly 100).
List<int> _toHundred(List<double> v) {
  final total = v.fold<double>(0, (a, b) => a + max(0, b));
  if (total <= 0) return List.filled(v.length, 0);
  final exact = [for (final x in v) max(0.0, x) / total * 100];
  final out = [for (final x in exact) x.floor()];
  var left = 100 - out.fold<int>(0, (a, b) => a + b);
  final order = List.generate(v.length, (i) => i)
    ..sort((a, b) => (exact[b] - out[b]).compareTo(exact[a] - out[a]));
  for (final i in order) {
    if (left <= 0) break;
    out[i]++;
    left--;
  }
  return out;
}

class _Column {
  final String name;
  final List<int> counts; // per category; the rest of 100 is drawn empty
  final String note; // the year, when the columns' years differ
  const _Column(this.name, this.counts, [this.note = '']);
}

class _PeopleChartPageState extends State<PeopleChartPage> {
  _Mode _mode = _Mode.question;

  // One question
  CatalogEntry? _entry;
  Dataset? _ds;
  // Causes of death
  List<Dataset>? _causes;
  Object? _error;

  /// Chosen countries (ISO3), two to four, in order.
  List<String> _isos = [];

  // Your own data
  final _ownCols = [TextEditingController(text: 'Group A'), TextEditingController(text: 'Group B')];
  final _ownCats = [
    TextEditingController(text: 'Yes'),
    TextEditingController(text: 'No'),
    TextEditingController(text: "Don't know"),
  ];
  // [column][category]
  final _ownVals = [
    [TextEditingController(text: '55'), TextEditingController(text: '35'), TextEditingController(text: '10')],
    [TextEditingController(text: '30'), TextEditingController(text: '60'), TextEditingController(text: '10')],
  ];
  final _ownSource = TextEditingController();

  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  int _ink = 0;
  bool _darkPoster = false;
  int _format = 0;
  final _boundary = GlobalKey();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final bySlug = catalogBySlug;
    final e = bySlug['findex-account-ownership'] ?? catalog.firstWhere(_isShareOfPeople, orElse: () => catalog.first);
    _pick(e);
  }

  @override
  void dispose() {
    for (final c in [..._ownCols, ..._ownCats, for (final r in _ownVals) ...r, _ownSource, _title, _subtitle]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── data ────────────────────────────────────────────────────────────────

  /// Latest value per country, with names and the years they come from.
  ({Map<String, double> values, Map<String, String> names, Map<String, String> years, String period}) _latest(
      Dataset? ds) {
    if (ds == null) return (values: {}, names: {}, years: {}, period: '');
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
    return (
      values: {for (final e in best.entries) e.key: e.value.value},
      names: {for (final e in best.entries) e.key: e.value.entity},
      years: {for (final e in best.entries) e.key: e.value.period},
      period: period,
    );
  }

  /// Highest, middle and lowest — the spread is the point of the picture.
  List<String> _spread(Map<String, double> v) {
    final s = v.keys.toList()..sort((a, b) => v[b]!.compareTo(v[a]!));
    if (s.length <= 3) return s;
    return [s.first, s[s.length ~/ 2], s.last];
  }

  Future<void> _pick(CatalogEntry e) async {
    setState(() {
      _entry = e;
      _ds = null;
      _error = null;
      _title.text = e.title;
      _subtitle.text = 'Out of every 100 ${_noun(e.slug)}';
    });
    try {
      final ds = await fetchDataset(e.slug);
      if (!mounted || _entry?.slug != e.slug) return;
      final l = _latest(ds);
      setState(() {
        _ds = ds;
        // Keep the user's countries where the new question has them.
        final kept = _isos.where(l.values.containsKey).toList();
        _isos = kept.length >= 2 ? kept : _spread(l.values);
      });
    } catch (err) {
      if (mounted) setState(() => _error = err);
    }
  }

  Future<void> _loadCauses() async {
    setState(() {
      _error = null;
      _title.text = 'What people die of';
      _subtitle.text = 'Out of every 100 deaths';
    });
    if (_causes != null) {
      setState(() => _isos = _spread(_latest(_causes![0]).values));
      return;
    }
    try {
      final all = await Future.wait(_causeSlugs.map(fetchDataset));
      if (!mounted) return;
      setState(() {
        _causes = all;
        _isos = _spread(_latest(all[0]).values);
      });
    } catch (err) {
      if (mounted) setState(() => _error = err);
    }
  }

  void _setMode(_Mode m) {
    setState(() => _mode = m);
    switch (m) {
      case _Mode.question:
        if (_entry != null) _pick(_entry!);
      case _Mode.causes:
        _loadCauses();
      case _Mode.own:
        setState(() {
          _error = null;
          _title.text = 'Who said yes';
          _subtitle.text = 'Out of every 100 people';
        });
    }
  }

  /// Country names for the picker: those the current data covers.
  Map<String, String> get _available => switch (_mode) {
        _Mode.question => _latest(_ds).names,
        _Mode.causes => _causes == null ? {} : _latest(_causes![0]).names,
        _Mode.own => {},
      };

  // ── what goes on the poster ─────────────────────────────────────────────

  ({List<_Column> cols, List<String> cats, List<Color> colors, String footer})? get _chart {
    final palette = _darkPoster
        ? _inks
        : const [Color(0xFFD9922A), Color(0xFF2E9683), Color(0xFF7B6BC9), Color(0xFFD63D42)];
    switch (_mode) {
      case _Mode.question:
        final ds = _ds;
        if (ds == null) return null;
        final l = _latest(ds);
        // The years of the countries on the picture, not of the whole series.
        final ys = {for (final iso in _isos) l.years[iso] ?? ''}..remove('');
        final years = (ys.toList()..sort());
        final period = years.isEmpty ? '' : years.length == 1 ? years.first : 'years under each country';
        return (
          cols: [
            for (final iso in _isos)
              if (l.values.containsKey(iso))
                _Column(l.names[iso] ?? iso, [l.values[iso]!.round().clamp(0, 100)],
                    years.length > 1 ? l.years[iso] ?? '' : '')
          ],
          cats: <String>[],
          colors: [palette[_ink]],
          footer: 'Source: ${_entry?.source ?? ds.source}${period.isEmpty ? '' : ' · $period'}',
        );
      case _Mode.causes:
        final c = _causes;
        if (c == null) return null;
        final ls = [for (final d in c) _latest(d)];
        return (
          cols: [
            for (final iso in _isos)
              if (ls.take(3).every((l) => l.values.containsKey(iso)))
                _Column(ls[0].names[iso] ?? iso, _toHundred([for (final l in ls) l.values[iso] ?? 0]))
          ],
          cats: _causeNames,
          colors: palette.take(4).toList(),
          footer: 'Source: WHO Global Health Estimates${ls[0].period.isEmpty ? '' : ' · ${ls[0].period}'}',
        );
      case _Mode.own:
        final src = _ownSource.text.trim();
        return (
          cols: [
            for (var i = 0; i < _ownCols.length; i++)
              _Column(_ownCols[i].text.trim(),
                  _toHundred([for (final v in _ownVals[i]) double.tryParse(v.text.replaceAll(',', '.').trim()) ?? 0]))
          ],
          cats: [for (final c in _ownCats) c.text.trim()],
          colors: palette.take(_ownCats.length).toList(),
          footer: src.isEmpty ? 'Data: the author\'s own' : 'Source: $src',
        );
    }
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final rb = _boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await rb.toImage(pixelRatio: 1080 / _posterW);
      final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bulldozer_people.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: '${_title.text.trim()} — made with BullDozer · azenha.ai/bulldozer',
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't create the image.")));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── own-data table editing ──────────────────────────────────────────────

  void _addOwnCol() => setState(() {
        _ownCols.add(TextEditingController(text: 'Group ${String.fromCharCode(65 + _ownCols.length)}'));
        _ownVals.add([for (var i = 0; i < _ownCats.length; i++) TextEditingController(text: '0')]);
      });

  void _removeOwnCol(int i) => setState(() {
        _ownCols.removeAt(i).dispose();
        for (final c in _ownVals.removeAt(i)) {
          c.dispose();
        }
      });

  void _addOwnCat() => setState(() {
        _ownCats.add(TextEditingController(text: 'Other'));
        for (final r in _ownVals) {
          r.add(TextEditingController(text: '0'));
        }
      });

  void _removeOwnCat(int j) => setState(() {
        _ownCats.removeAt(j).dispose();
        for (final r in _ownVals) {
          r.removeAt(j).dispose();
        }
      });

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final chart = _chart;
    final poster = chart == null || chart.cols.isEmpty
        ? null
        : _Poster(
            title: _title.text,
            subtitle: _subtitle.text,
            cols: chart.cols,
            cats: chart.cats,
            colors: chart.colors,
            footer: chart.footer,
            dark: _darkPoster,
            aspect: _formats[_format].$2,
          );
    final names = _available;
    final shares = catalog.where(_isShareOfPeople).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('People chart', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (_error != null)
                SizedBox(
                    height: 320,
                    child: LoadError(
                        error: _error!, what: 'this indicator', onRetry: () => _setMode(_mode)))
              else if (poster == null)
                SizedBox(height: 320, child: Center(child: CircularProgressIndicator(color: kAmber)))
              else
                FittedBox(child: RepaintBoundary(key: _boundary, child: poster)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: poster == null || _busy ? null : _share,
                style: FilledButton.styleFrom(backgroundColor: kAmber, foregroundColor: kBg),
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.ios_share),
                label: const Text('Share image', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              _label('Chart'),
              _chips(const ['One question', 'Causes of death', 'Your own data'], _mode.index,
                  (i) => _setMode(_Mode.values[i])),
              if (_mode == _Mode.question) ...[
                _label('Question'),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    title: Text(_entry?.title ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(_entry?.source ?? '', style: TextStyle(color: kTextDim, fontSize: 12)),
                    trailing: const Icon(Icons.unfold_more),
                    onTap: () => showSearchSheet<CatalogEntry>(
                      context,
                      title: 'Choose a share of people',
                      items: shares,
                      label: (e) => e.title,
                      sub: (e) => e.source,
                      onPick: _pick,
                    ),
                  ),
                ),
              ],
              if (_mode != _Mode.own) ...[
                _label('Countries'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final iso in _isos)
                    InputChip(
                      label: Text(names[iso] ?? iso),
                      onDeleted: _isos.length > 1 ? () => setState(() => _isos.remove(iso)) : null,
                    ),
                  if (_isos.length < 4 && names.isNotEmpty)
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: const Text('Add country'),
                      onPressed: () {
                        final items = (names.entries.where((e) => !_isos.contains(e.key)).toList()
                          ..sort((a, b) => a.value.compareTo(b.value)));
                        showSearchSheet<MapEntry<String, String>>(
                          context,
                          title: 'Add a country',
                          items: items,
                          label: (e) => e.value,
                          sub: (e) => e.key,
                          onPick: (e) => setState(() => _isos.add(e.key)),
                        );
                      },
                    ),
                ]),
                const SizedBox(height: 6),
                Text('Starts with the highest, a middle and the lowest country — change them freely.',
                    style: TextStyle(color: kTextDim, fontSize: 12)),
              ],
              if (_mode == _Mode.own) ..._ownEditor(),
              _label('Title'),
              TextField(
                controller: _title,
                maxLength: 90,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ''),
              ),
              _label('Subtitle'),
              TextField(
                controller: _subtitle,
                maxLength: 60,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ''),
              ),
              if (_mode == _Mode.question) ...[
                _label('Colour'),
                Wrap(spacing: 10, children: [
                  for (var i = 0; i < _inks.length; i++)
                    GestureDetector(
                      onTap: () => setState(() => _ink = i),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _inks[i],
                          shape: BoxShape.circle,
                          border: Border.all(color: i == _ink ? kText : Colors.transparent, width: 2.5),
                        ),
                      ),
                    ),
                ]),
              ],
              _label('Background'),
              _chips(const ['Light', 'Dark'], _darkPoster ? 1 : 0, (i) => setState(() => _darkPoster = i == 1)),
              _label('Format'),
              _chips([for (final f in _formats) f.$1], _format, (i) => setState(() => _format = i)),
              const SizedBox(height: 10),
              Text(
                'Each figure is one in a hundred, so values are rounded to whole people: '
                'a gap under one point does not show. The numbers stay the source\'s.',
                style: TextStyle(color: kTextDim, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _ownEditor() => [
        _label('Groups (columns)'),
        for (var i = 0; i < _ownCols.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: _field(_ownCols[i], maxLength: 24)),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _ownCols.length > 1 ? () => _removeOwnCol(i) : null,
                ),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                for (var j = 0; j < _ownCats.length; j++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _field(_ownVals[i][j],
                          number: true, hint: _ownCats[j].text, dot: j < _inks.length ? _inks[j] : null),
                    ),
                  ),
              ]),
            ]),
          ),
        if (_ownCols.length < 4)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(onPressed: _addOwnCol, icon: const Icon(Icons.add), label: const Text('Add group')),
          ),
        _label('Answers (colours)'),
        for (var j = 0; j < _ownCats.length; j++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: _inks[j], borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 10),
              Expanded(child: _field(_ownCats[j], maxLength: 28)),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: _ownCats.length > 2 ? () => _removeOwnCat(j) : null,
              ),
            ]),
          ),
        if (_ownCats.length < 4)
          Align(
            alignment: Alignment.centerLeft,
            child:
                TextButton.icon(onPressed: _addOwnCat, icon: const Icon(Icons.add), label: const Text('Add answer')),
          ),
        Text('Counts or percentages — each group is scaled to 100 figures.',
            style: TextStyle(color: kTextDim, fontSize: 12)),
        _label('Source'),
        _field(_ownSource, maxLength: 60, hint: 'Where the numbers come from'),
      ];

  Widget _field(TextEditingController c, {int? maxLength, bool number = false, String? hint, Color? dot}) =>
      TextField(
        controller: c,
        maxLength: maxLength,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : null,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          isDense: true,
          border: const OutlineInputBorder(),
          counterText: '',
          hintText: hint,
          labelText: number ? hint : null,
          prefixIcon: dot == null
              ? null
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(width: 10, height: 10, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                ),
          prefixIconConstraints: const BoxConstraints(minWidth: 30),
        ),
      );

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

/// The exported picture, in its own fixed colours.
class _Poster extends StatelessWidget {
  final String title, subtitle, footer;
  final List<_Column> cols;
  final List<String> cats;
  final List<Color> colors;
  final bool dark;
  final double aspect;

  const _Poster({
    required this.title,
    required this.subtitle,
    required this.cols,
    required this.cats,
    required this.colors,
    required this.footer,
    required this.dark,
    required this.aspect,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF0E0F11) : const Color(0xFFFFFFFF);
    final ink = dark ? const Color(0xFFF2F3F5) : const Color(0xFF15171A);
    final dim = dark ? const Color(0xFF9AA1A9) : const Color(0xFF5F6670);
    final empty = dark ? const Color(0xFF3A3F46) : const Color(0xFFD5D7DB);
    final t = title.trim().isEmpty ? ' ' : title.trim();
    final titleSize = t.length > 60 ? 18.0 : t.length > 36 ? 21.0 : 24.0;
    final single = cats.isEmpty;
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
              Text(t,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ink, fontSize: titleSize, fontWeight: FontWeight.w800, height: 1.1)),
              if (subtitle.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(subtitle.trim(),
                      textAlign: TextAlign.center, style: TextStyle(color: dim, fontSize: 11, height: 1.2)),
                ),
              if (!single)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 3,
                    children: [
                      for (var j = 0; j < cats.length; j++)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: colors[j], shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(cats[j],
                              style: TextStyle(color: ink, fontSize: 9, fontWeight: FontWeight.w600)),
                        ]),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final c in cols)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 26,
                                child: Text(c.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: ink, fontSize: cols.length > 3 ? 9 : 11, fontWeight: FontWeight.w700, height: 1.15)),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: CustomPaint(
                                  painter: _PeoplePainter(c.counts, colors, empty),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (single)
                                Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                        text: '${c.counts.first}',
                                        style: TextStyle(color: colors.first, fontSize: 20, fontWeight: FontWeight.w900)),
                                    TextSpan(text: ' of 100', style: TextStyle(color: dim, fontSize: 9)),
                                  ]),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                ),
                              // A year line under every column or none, so the grids stay level.
                              if (single && cols.any((x) => x.note.isNotEmpty))
                                Text(c.note.isEmpty ? ' ' : c.note,
                                    textAlign: TextAlign.center, style: TextStyle(color: dim, fontSize: 8.5)),
                              if (!single)
                                Text.rich(
                                  TextSpan(children: [
                                    for (var j = 0; j < c.counts.length; j++) ...[
                                      if (j > 0) TextSpan(text: ' · ', style: TextStyle(color: dim, fontSize: 9)),
                                      TextSpan(
                                          text: '${c.counts[j]}',
                                          style: TextStyle(
                                              color: colors[j % colors.length], fontSize: 13, fontWeight: FontWeight.w900)),
                                    ],
                                  ]),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
                child: Text('azenha.ai/bulldozer', textAlign: TextAlign.right, style: TextStyle(color: dim, fontSize: 7.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 100 figures, ten to a row, filled from the top in category order; the
/// rest of the hundred is drawn in the empty colour.
class _PeoplePainter extends CustomPainter {
  final List<int> counts;
  final List<Color> colors;
  final Color empty;
  _PeoplePainter(this.counts, this.colors, this.empty);

  @override
  void paint(Canvas canvas, Size size) {
    // A figure is twice as tall as it is wide. Pick the layout of the hundred
    // (5×20 … 25×4) that gives the biggest figures in this box, and centre it.
    var perRow = 10;
    var cw = 0.0;
    for (final n in const [4, 5, 10, 20, 25]) {
      final w = min(size.width / n, size.height / (100 / n) / 2);
      if (w > cw) {
        cw = w;
        perRow = n;
      }
    }
    final rows = 100 ~/ perRow;
    final ch = cw * 2;
    final ox = (size.width - cw * perRow) / 2;
    final oy = (size.height - ch * rows) / 2;
    final fills = <Color>[
      for (var j = 0; j < counts.length; j++) ...List.filled(counts[j], colors[j % colors.length]),
    ];
    final p = Paint()..isAntiAlias = true;
    for (var k = 0; k < perRow * rows; k++) {
      p.color = k < fills.length ? fills[k] : empty;
      final x = ox + (k % perRow) * cw, y = oy + (k ~/ perRow) * ch;
      final cx = x + cw / 2;
      // Head, then a body with rounded shoulders and a gap between the legs.
      canvas.drawCircle(Offset(cx, y + ch * 0.17), cw * 0.2, p);
      final body = RRect.fromRectAndCorners(
        Rect.fromLTRB(cx - cw * 0.3, y + ch * 0.32, cx + cw * 0.3, y + ch * 0.66),
        topLeft: Radius.circular(cw * 0.22),
        topRight: Radius.circular(cw * 0.22),
      );
      canvas.drawRRect(body, p);
      canvas.drawRect(Rect.fromLTRB(cx - cw * 0.22, y + ch * 0.64, cx - cw * 0.03, y + ch * 0.94), p);
      canvas.drawRect(Rect.fromLTRB(cx + cw * 0.03, y + ch * 0.64, cx + cw * 0.22, y + ch * 0.94), p);
    }
  }

  @override
  bool shouldRepaint(_PeoplePainter o) => o.counts != counts || o.colors != colors || o.empty != empty;
}
