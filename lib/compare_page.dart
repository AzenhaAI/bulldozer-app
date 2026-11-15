import 'package:flutter/material.dart';

import 'api.dart';
import 'catalog_store.dart';
import 'theme.dart';
import 'widgets/sample_stats.dart';
import 'widgets/search_sheet.dart';

const _maxCountries = 5;

/// Compare up to 5 countries on one indicator — ranked bars of their latest
/// values. Reached from a country profile (that country is pre-selected), and
/// hosted directly inside the Geo tab, which is where the site puts it too.
class ComparePage extends StatefulWidget {
  final Country? initial;
  final List<Country> allCountries;

  /// True when the Geo tab hosts this as one of its views: the page then drops
  /// its own Scaffold and app bar, which would otherwise stack a second title
  /// under the tab's own.
  final bool embedded;
  const ComparePage(
      {super.key,
      this.initial,
      this.allCountries = const [],
      this.embedded = false});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  final List<Country> _selected = [];
  CatalogEntry? _indicator;
  Dataset? _ds;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _selected.add(widget.initial!);
    // Default indicator: the first of these that the catalog (and the
    // initial country, when we came from a profile) actually carries — not catalog[0], which is alphabetical and landed the
    // Geo tab on "Acceptance of Homosexuality (EVS)" as its opening view. A
    // headline economic measure is the neutral thing to compare first.
    const preferred = [
      'imf-gdp-per-capita-ppp',
      'wb-life-expectancy',
      'gapminder-life-expectancy',
      'gapminder-income',
    ];
    // Survey sets (Eurobarometer, EVS, ISSP) cover a few dozen countries and
    // are no neutral opening view — never land on one by default.
    bool neutral(String s) =>
        !s.startsWith('eb-') && !s.startsWith('evs-') && !s.startsWith('issp-');
    final bySlug = catalogBySlug;
    final own = [
      for (final it in widget.initial?.items ?? const <CountryItem>[]) it.slug
    ];
    final slug = preferred
            .where((p) => bySlug.containsKey(p) && (own.isEmpty || own.contains(p)))
            .firstOrNull ??
        own.where((s) => bySlug.containsKey(s) && neutral(s)).firstOrNull ??
        preferred.where(bySlug.containsKey).firstOrNull ??
        catalog.map((e) => e.slug).where(neutral).firstOrNull;
    _indicator = slug != null ? catalogBySlug[slug] : null;
    if (_indicator != null) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ds = await fetchDataset(_indicator!.slug);
      if (mounted) setState(() => _ds = ds);
    } catch (_) {
      // leave _ds null — the body shows a hint
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Each country's latest value: the sample the world median is taken over.
  List<double> _worldLatest() {
    final latest = <String, Observation>{};
    for (final o in _ds?.data ?? const <Observation>[]) {
      if (o.iso.isEmpty || !o.value.isFinite) continue;
      final cur = latest[o.iso];
      if (cur == null || o.period.compareTo(cur.period) > 0) latest[o.iso] = o;
    }
    return [for (final o in latest.values) o.value];
  }

  Observation? _latest(String iso) {
    final rows = (_ds?.data ?? [])
        .where((o) => o.iso == iso && o.value.isFinite)
        .toList();
    if (rows.isEmpty) return null;
    rows.sort((a, b) => a.period.compareTo(b.period));
    return rows.last;
  }

  /// "2024", or "2026 est." for an IMF year at or past the first projected one.
  String _yearLabel(String period) {
    final from = _ds?.projectedFrom;
    final y = double.tryParse(period.length >= 4 ? period.substring(0, 4) : period);
    return from != null && y != null && y >= from ? '$period est.' : period;
  }

  void _pickIndicator() {
    showSearchSheet<CatalogEntry>(
      context,
      title: 'Choose an indicator',
      items: catalog,
      label: (e) => e.title,
      sub: (e) => e.source,
      onPick: (e) {
        setState(() => _indicator = e);
        _load();
      },
    );
  }

  void _addCountry() {
    final pool = widget.allCountries
        .where((c) => !_selected.any((s) => s.iso == c.iso))
        .toList();
    showSearchSheet<Country>(
      context,
      title: 'Add a country',
      items: pool,
      label: (c) => c.name,
      sub: (c) => c.region,
      onPick: (c) => setState(() => _selected.add(c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rows sorted by value desc; countries without data go last.
    final rows = _selected
        .map((c) => (c, _latest(c.iso)))
        .toList()
      ..sort((a, b) =>
          (b.$2?.value ?? -1e30).compareTo(a.$2?.value ?? -1e30));
    // Bars scale to the largest latest value of any country, so a single
    // country reads against the world, not as a full bar of itself.
    final world = _worldLatest();
    final maxAbs = [
      ...world.map((v) => v.abs()),
      ...rows.map((r) => (r.$2?.value ?? 0).abs()),
    ].fold<double>(0, (a, b) => a > b ? a : b);

    final body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Indicator selector
          InkWell(
            onTap: _pickIndicator,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.bar_chart, color: kAmber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_indicator?.title ?? 'Choose an indicator',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        if (_indicator != null)
                          Text('${_indicator!.source} · ${_indicator!.unit}',
                              style: TextStyle(
                                  fontSize: 11, color: kTextDim)),
                      ],
                    ),
                  ),
                  Icon(Icons.expand_more, color: kTextDim),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Country chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _selected)
                InputChip(
                  label: Text(c.name, style: const TextStyle(fontSize: 12)),
                  onDeleted: () => setState(() => _selected.remove(c)),
                  deleteIconColor: kTextDim,
                ),
              if (_selected.length < _maxCountries &&
                  widget.allCountries.isNotEmpty)
                ActionChip(
                  avatar: Icon(Icons.add, size: 16, color: kAmber),
                  label: const Text('Add country',
                      style: TextStyle(fontSize: 12)),
                  onPressed: _addCountry,
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: kAmber)),
            )
          else if (_indicator == null)
            const _Hint('Pick an indicator to compare.')
          else if (_ds == null)
            const _Hint('Couldn\'t load this indicator.')
          else if (_selected.isEmpty)
            const _Hint('Add countries to compare.')
          else
            for (final r in rows)
              _CompareBar(
                name: r.$1.name,
                value: r.$2?.value,
                year: r.$2 == null ? null : _yearLabel(r.$2!.period),
                unit: _indicator!.unit,
                fraction: maxAbs == 0 || r.$2 == null
                    ? 0
                    : (r.$2!.value.abs() / maxAbs),
                negative: (r.$2?.value ?? 0) < 0,
              ),
          if (_ds != null && _selected.isNotEmpty && !_loading)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Bars scale to the highest value of any country.',
                  style: TextStyle(fontSize: 11, color: kTextDim)),
            ),
          // Five countries alone have no middle worth naming: set them
          // against the median of every country's latest reading.
          if (_ds != null && _selected.isNotEmpty) ...[
            const SizedBox(height: 10),
            SampleStats(values: world, unit: _indicator?.unit ?? '', prefix: 'World, latest reading each: '),
            chartWatermark,
          ],
        ],
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: body,
    );
  }
}

class _CompareBar extends StatelessWidget {
  final String name;
  final double? value;
  final String? year;
  final String unit;
  final double fraction;
  final bool negative;
  const _CompareBar({
    required this.name,
    required this.value,
    this.year,
    required this.unit,
    required this.fraction,
    required this.negative,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: value == null
                          ? 'no data'
                          : formatWithUnit(value!, unit),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: value == null ? kTextDim : kText)),
                  if (value != null && year != null && year!.isNotEmpty)
                    TextSpan(
                        text: '  $year',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: kTextDim)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: negative ? kDown : kAmber,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
            child: Text(text,
                style: TextStyle(color: kTextDim), textAlign: TextAlign.center)),
      );
}
