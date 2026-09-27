import 'package:flutter/material.dart';

import 'api.dart';
import 'catalog_store.dart';
import 'charts_page.dart';
import 'countries_page.dart';
import 'flags.dart';
import 'theme.dart';

/// "Ask AI" — type a country, get what the catalogue holds on it and where it
/// stands out in the world.
///
/// A tester asked for it. It is labelled as in development because no model
/// writes the answer yet: every line is a published value with its year, rank
/// and source, selected by the site (`/data/brief/<iso>.json`, see
/// countryBrief.ts in the site repo). Nothing is generated, so nothing can be
/// invented — the rule the whole product runs on.
class AskPage extends StatefulWidget {
  const AskPage({super.key});
  @override
  State<AskPage> createState() => _AskPageState();
}

class _Brief {
  final String iso, name, region, since, latest;
  final int indicators;
  final List<(String, int)> topics;
  final List<Map<String, dynamic>> standouts;
  _Brief.fromJson(Map<String, dynamic> j)
      : iso = j['iso'] ?? '',
        name = j['name'] ?? '',
        region = j['region'] ?? '',
        since = '${j['since'] ?? ''}',
        latest = '${j['latest'] ?? ''}',
        indicators = j['indicators'] ?? 0,
        topics = [
          for (final t in (j['topics'] as List? ?? []))
            ('${t['label']}', (t['count'] as num).toInt())
        ],
        standouts = [
          for (final s in (j['standouts'] as List? ?? []))
            Map<String, dynamic>.from(s as Map)
        ];
}

class _AskPageState extends State<AskPage> {
  final _ctl = TextEditingController();
  List<Country>? _countries;
  String _query = '';
  _Brief? _brief;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchCountryIndex().then((c) {
      if (mounted) setState(() => _countries = c..sort((a, b) => a.name.compareTo(b.name)));
    }).catchError((_) {
      if (mounted) setState(() => _error = 'Could not load the country list. Check the connection.');
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  List<Country> get _matches {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty || _countries == null) return const [];
    return _countries!
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.official.toLowerCase().contains(q) ||
            c.iso.toLowerCase() == q)
        .take(8)
        .toList();
  }

  Future<void> _ask(Country c) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _brief = null;
      _query = '';
      _ctl.text = c.name;
    });
    try {
      final j = await fetchJson('/data/brief/${c.iso.toLowerCase()}.json');
      if (mounted) setState(() => _brief = _Brief.fromJson(j as Map<String, dynamic>));
    } catch (_) {
      if (mounted) setState(() => _error = 'No answer for ${c.name} right now. Check the connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Trailing zeros dropped (85, not 85.0); a percent sign sits on the number.
  String _num(num v) {
    final a = v.abs();
    var t = a >= 1000 ? v.toStringAsFixed(0) : v.toStringAsFixed(a >= 100 ? 1 : 2);
    if (t.contains('.')) t = t.replaceAll(RegExp(r'\.?0+$'), '');
    return t;
  }

  String _withUnit(num v, String unit) => unit == '%' ? '${_num(v)}%' : '${_num(v)} $unit';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(children: [
          Text('Ask AI', style: pageTitleStyle),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                border: Border.all(color: kAmber), borderRadius: BorderRadius.circular(6)),
            child: Text('IN DEVELOPMENT',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: kAmber)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
            'Type a country to see what we hold on it and where it stands out. '
            'For now every answer is built only from our published data — each line '
            'with its year, world rank and source — so nothing is made up.',
            style: TextStyle(fontSize: 13, color: kTextDim, height: 1.4)),
        const SizedBox(height: 14),
        TextField(
          controller: _ctl,
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _query = v),
          onSubmitted: (_) {
            final m = _matches;
            if (m.isNotEmpty) _ask(m.first);
          },
          decoration: InputDecoration(
            hintText: 'A country — e.g. Kazakhstan, Brazil, JPN',
            prefixIcon: const Icon(Icons.auto_awesome_outlined),
            isDense: true,
            filled: true,
            fillColor: kBgCard,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: kBorder, width: 0.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: kBorder, width: 0.5)),
          ),
        ),
        for (final c in _matches)
          ListTile(
            dense: true,
            leading: Text(flagFromIso(c.iso), style: const TextStyle(fontSize: 20)),
            title: Text(c.name),
            subtitle: Text(c.region, style: TextStyle(color: kTextDim, fontSize: 12)),
            onTap: () => _ask(c),
          ),
        if (_loading)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!, style: TextStyle(color: kTextDim))),
        if (_brief != null) ..._answer(_brief!),
      ],
    );
  }

  List<Widget> _answer(_Brief b) {
    final country = _countries?.where((c) => c.iso == b.iso).firstOrNull;
    return [
      const SizedBox(height: 18),
      Text('${flagFromIso(b.iso)}  ${b.name}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(
          'We hold ${b.indicators} indicators on ${b.name}, in ${b.topics.length} topics, '
          'with figures from ${b.since} to ${b.latest}.',
          style: TextStyle(color: kTextDim, fontSize: 13, height: 1.4)),
      const SizedBox(height: 10),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final (label, n) in b.topics)
          Chip(
            label: Text('$label · $n', style: const TextStyle(fontSize: 12)),
            visualDensity: VisualDensity.compact,
          ),
      ]),
      const SizedBox(height: 18),
      Text('WHERE IT STANDS OUT',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: kAmber)),
      const SizedBox(height: 4),
      if (b.standouts.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
              'Nowhere near the top or bottom tenth of the world on recent data — '
              'a country in the middle of most rankings.',
              style: TextStyle(color: kTextDim)),
        ),
      for (final s in b.standouts)
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text('${s['title']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(
                '${_withUnit(s['value'] as num, '${s['unit']}')} (${s['period']}) · '
                '#${s['rank']} of ${s['total']} — among the ${s['side'] == 'high' ? 'highest' : 'lowest'} in the world\n'
                'Source: ${s['source']}',
                style: TextStyle(fontSize: 12, color: kTextDim, height: 1.35)),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              final e = catalogBySlug['${s['slug']}'];
              if (e != null) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => DatasetPage(entry: e)));
              }
            },
          ),
        ),
      const SizedBox(height: 8),
      Text(
          '"Highest" and "lowest" describe the value, not whether it is good: '
          'first on child mortality is the worst place to be.',
          style: TextStyle(fontSize: 11, color: kTextDim, fontStyle: FontStyle.italic)),
      if (country != null) ...[
        const SizedBox(height: 14),
        OutlinedButton.icon(
          icon: const Icon(Icons.public_outlined, size: 18),
          label: Text('All ${b.indicators} indicators for ${b.name}'),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CountryPage(country: country, allCountries: _countries ?? const []))),
        ),
      ],
    ];
  }
}
