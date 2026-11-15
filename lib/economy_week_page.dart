import 'package:flutter/material.dart';

import 'api.dart';
import 'flags.dart';
import 'theme.dart';
import 'widgets/load_error.dart';

/// "Economy this week": the site's weekly table of headline indicators for
/// 43 economies (output, prices, jobs, external and fiscal balances, bond
/// yields, currencies) plus commodities — the format of The Economist's back
/// pages, from open sources only. Each figure keeps its own period and source.
/// Data: /data/economy.json, rebuilt weekly with the site (owner, 15 Nov 2026).

class EconFig {
  final double? value;
  final String period, source;
  final double? change; // bp for yields, % y/y for currencies
  const EconFig(this.value, this.period, this.source, [this.change]);

  static EconFig? from(dynamic j, {String changeKey = ''}) {
    if (j is num) return EconFig(j.toDouble(), '', '');
    if (j is! Map) return null;
    final v = j['value'] ?? j['perUsd'];
    return EconFig(
      v is num ? v.toDouble() : null,
      '${j['period'] ?? ''}',
      '${j['source'] ?? ''}',
      changeKey.isEmpty || j[changeKey] is! num ? null : (j[changeKey] as num).toDouble(),
    );
  }
}

class EconRow {
  final String iso, name;
  final Map<String, EconFig?> f;
  EconRow(this.iso, this.name, this.f);
}

class _Col {
  final String key, label, hint;
  final String Function(EconFig) fmt;
  const _Col(this.key, this.label, this.hint, this.fmt);
}

/// "$102 a barrel" from 102 and "$ a barrel"; other units follow the number.
String _withUnit(double v, String unit) => unit.startsWith(r'$ ')
    ? '\$${formatValue(v)} ${unit.substring(2)}'
    : '${formatValue(v)} $unit'.trim();

String _pct(double v) => '${v.toStringAsFixed(1)}%';
String _signed(double v, [int dp = 1]) => '${v > 0 ? '+' : ''}${v.toStringAsFixed(dp)}';

class EconomyWeek {
  final String asOf;
  final int? forecastYear;
  final List<EconRow> rows;
  final List<Map<String, dynamic>> commodities;
  EconomyWeek(this.asOf, this.forecastYear, this.rows, this.commodities);

  static EconomyWeek parse(Map<String, dynamic> j) {
    final rows = <EconRow>[];
    for (final r in (j['rows'] as List? ?? const [])) {
      if (r is! Map) continue;
      rows.add(EconRow('${r['iso'] ?? ''}', '${r['name'] ?? ''}', {
        'gdp': EconFig.from(r['gdp']),
        'gdpQoqAnn': EconFig.from(r['gdpQoqAnn']),
        'gdpForecast': EconFig.from(r['gdpForecast']),
        'cpi': EconFig.from(r['cpi']),
        'cpiForecast': EconFig.from(r['cpiForecast']),
        'unemployment': EconFig.from(r['unemployment']),
        'currentAccount': EconFig.from(r['currentAccount']),
        'budgetBalance': EconFig.from(r['budgetBalance']),
        'yield10y': EconFig.from(r['yield10y'], changeKey: 'changeBp'),
        'currency': EconFig.from(r['currency'], changeKey: 'changeYoy'),
      }));
    }
    return EconomyWeek(
      '${j['asOf'] ?? ''}',
      int.tryParse('${j['forecastYear'] ?? ''}'),
      rows,
      [for (final c in (j['commodities'] as List? ?? const [])) if (c is Map) Map<String, dynamic>.from(c)],
    );
  }
}

Future<EconomyWeek> fetchEconomyWeek() async =>
    EconomyWeek.parse(Map<String, dynamic>.from(await fetchJson('/data/economy.json') as Map));

String _asOfLabel(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

/// Entry card on the Biz tab: the as-of date and three moves of the week.
class EconomyWeekCard extends StatefulWidget {
  const EconomyWeekCard({super.key});
  @override
  State<EconomyWeekCard> createState() => _EconomyWeekCardState();
}

class _EconomyWeekCardState extends State<EconomyWeekCard> {
  late final Future<EconomyWeek> _f = fetchEconomyWeek();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EconomyWeekPage())),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: FutureBuilder<EconomyWeek>(
            future: _f,
            builder: (context, snap) {
              final w = snap.data;
              final facts = <String>[];
              if (w != null) {
                for (final c in w.commodities.take(2)) {
                  final v = c['value'], ch = c['changeMonth'];
                  if (v is num && ch is num) {
                    facts.add('${c['name']} ${_withUnit(v.toDouble(), '${c['unit'] ?? ''}')} (${_signed(ch.toDouble())}% m/m)');
                  }
                }
                final us = w.rows.where((r) => r.iso == 'USA').firstOrNull;
                final y = us?.f['yield10y'];
                if (y?.value != null) {
                  facts.add('US 10-year ${y!.value!.toStringAsFixed(2)}%${y.change == null ? '' : ' (${_signed(y.change!, 0)} bp y/y)'}');
                }
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('🗞️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Economy this week',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.2)),
                    const SizedBox(height: 4),
                    Text(
                        w == null
                            ? 'GDP, inflation, jobs, bond yields and currencies for 43 economies'
                            : '43 economies and commodities · as of ${_asOfLabel(w.asOf)}',
                        style: TextStyle(fontSize: 12, color: kTextDim, height: 1.35)),
                    for (final f in facts)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAmberText)),
                      ),
                  ]),
                ),
                Icon(Icons.chevron_right, color: kTextDim, size: 20),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class EconomyWeekPage extends StatefulWidget {
  const EconomyWeekPage({super.key});
  @override
  State<EconomyWeekPage> createState() => _EconomyWeekPageState();
}

class _EconomyWeekPageState extends State<EconomyWeekPage> {
  late Future<EconomyWeek> _f = fetchEconomyWeek();
  int _set = 0;
  String _sortKey = 'gdp';
  bool _desc = true;

  List<(String, List<_Col>)> _sets(int? fy) => [
        (
          'Output & prices',
          [
            _Col('gdp', 'GDP\ny/y', 'Real GDP, % change on a year earlier', (f) => _pct(f.value!)),
            _Col('gdpQoqAnn', 'GDP\nq/q ann.', 'Latest quarter on the one before, annualised', (f) => _pct(f.value!)),
            _Col('gdpForecast', 'GDP\n${fy ?? ''} fcst', 'IMF WEO forecast for the year', (f) => _pct(f.value!)),
            _Col('cpi', 'Inflation\ny/y', 'Consumer prices, % change on a year earlier', (f) => _pct(f.value!)),
            _Col('cpiForecast', 'Inflation\n${fy ?? ''} fcst', 'IMF WEO forecast for the year', (f) => _pct(f.value!)),
            _Col('unemployment', 'Jobless\nrate', 'Unemployment, % of the labour force', (f) => _pct(f.value!)),
          ]
        ),
        (
          'Balances, rates & money',
          [
            _Col('currentAccount', 'Current acct\n% of GDP', 'IMF WEO estimate for the year', (f) => _signed(f.value!)),
            _Col('budgetBalance', 'Budget\n% of GDP', 'General government balance, IMF WEO', (f) => _signed(f.value!)),
            _Col('yield10y', '10-yr yield\n%', '10-year government bond; change in basis points on a year earlier',
                (f) => '${f.value!.toStringAsFixed(2)}${f.change == null ? '' : '  ${_signed(f.change!, 0)}bp'}'),
            _Col('currency', 'Per \$', 'Units of currency per US dollar; % change on a year earlier',
                (f) => '${formatValue(f.value!)}${f.change == null ? '' : '  ${_signed(f.change!)}%'}'),
          ]
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Economy this week', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
      body: FutureBuilder<EconomyWeek>(
        future: _f,
        builder: (context, snap) {
          if (snap.hasError) {
            return LoadError(
                error: snap.error!, what: 'the weekly table', onRetry: () => setState(() => _f = fetchEconomyWeek()));
          }
          final w = snap.data;
          if (w == null) return Center(child: CircularProgressIndicator(color: kAmber));
          final sets = _sets(w.forecastYear);
          final cols = sets[_set].$2;
          if (!cols.any((c) => c.key == _sortKey)) _sortKey = cols.first.key;
          final rows = [...w.rows]..sort((a, b) {
              final x = a.f[_sortKey]?.value, y = b.f[_sortKey]?.value;
              if (x == null && y == null) return a.name.compareTo(b.name);
              if (x == null) return 1;
              if (y == null) return -1;
              return _desc ? y.compareTo(x) : x.compareTo(y);
            });
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(
                'Headline figures for 43 economies, each with its own latest period — as of ${_asOfLabel(w.asOf)}. '
                'Forecasts are the IMF World Economic Outlook. Tap a column to sort.',
                style: TextStyle(fontSize: 12, color: kTextDim, height: 1.4)),
            const SizedBox(height: 10),
            SegmentedButton<int>(
              segments: [for (var i = 0; i < sets.length; i++) ButtonSegment(value: i, label: Text(sets[i].$1))],
              selected: {_set},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _set = s.first),
            ),
            const SizedBox(height: 8),
            // Country names stay put while the figures scroll sideways: a
            // scrolled row had lost its label (QA, 15 Nov 2026). Two tables
            // with the same fixed row heights, side by side.
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              DataTable(
                columnSpacing: 0,
                horizontalMargin: 4,
                headingRowHeight: 44,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 48,
                columns: const [DataColumn(label: Text('', style: TextStyle(fontSize: 11)))],
                rows: [
                  for (final r in rows)
                    DataRow(cells: [
                      DataCell(SizedBox(
                        width: 104,
                        child: Text('${r.iso.length == 3 ? '${flagFromIso(r.iso)} ' : ''}${r.name}',
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.15)),
                      )),
                    ]),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 14,
                    horizontalMargin: 6,
                    headingRowHeight: 44,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 48,
                    sortColumnIndex: cols.indexWhere((c) => c.key == _sortKey),
                    sortAscending: !_desc,
                    columns: [
                      for (final c in cols)
                        DataColumn(
                          numeric: true,
                          tooltip: c.hint,
                          label: Text(c.label, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          onSort: (_, _) => setState(() {
                            if (_sortKey == c.key) {
                              _desc = !_desc;
                            } else {
                              _sortKey = c.key;
                              _desc = true;
                            }
                          }),
                        ),
                    ],
                    rows: [
                      for (final r in rows)
                        DataRow(cells: [for (final c in cols) DataCell(_cell(r.f[c.key], c))]),
                    ],
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Text('COMMODITIES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: kAmberText)),
            const SizedBox(height: 6),
            for (final c in w.commodities)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Expanded(
                    child: Text('${c['name']}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Text(c['value'] is num ? _withUnit((c['value'] as num).toDouble(), '${c['unit'] ?? ''}') : '–',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 150,
                    child: Text(
                        [
                          if (c['changeMonth'] is num) '${_signed((c['changeMonth'] as num).toDouble())}% m/m',
                          if (c['changeYear'] is num) '${_signed((c['changeYear'] as num).toDouble())}% y/y',
                        ].join('  '),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: kTextDim)),
                  ),
                ]),
              ),
            if (w.commodities.isNotEmpty)
              Text('${w.commodities.first['period'] ?? ''} · ${w.commodities.first['source'] ?? ''} primary commodity prices',
                  style: TextStyle(fontSize: 11, color: kTextDim)),
            const SizedBox(height: 12),
            Text(
                'Sources: OECD, Eurostat, IMF, central banks (each cell shows its period). Figures are as published; '
                'GDP and inflation are revised by their sources.',
                style: TextStyle(fontSize: 11, color: kTextDim, height: 1.4)),
            const SizedBox(height: 8),
            chartWatermark,
          ]);
        },
      ),
    );
  }

  Widget _cell(EconFig? f, _Col c) {
    if (f == null || f.value == null) return Text('–', style: TextStyle(fontSize: 12, color: kTextDim));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(c.fmt(f), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        if (f.period.isNotEmpty)
          Text(f.period, style: TextStyle(fontSize: 9.5, color: kTextDim)),
      ],
    );
  }
}
