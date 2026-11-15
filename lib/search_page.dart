import 'package:flutter/material.dart';

import 'api.dart';
import 'catalog_store.dart';
import 'charts_page.dart';
import 'countries_page.dart';
import 'flags.dart';
import 'theme.dart';

/// Global search — one field that matches both countries and indicators,
/// reachable from the Home header.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

/// How well [query] matches [text]: 0 is no match. Every query word must
/// match a word of the text — as its start ("adul" → "Adult"), inside it, or
/// one typo away ("mortalty" → "Mortality") — so "adul mortality" finds
/// "Adult Mortality" (reviewers, 15 Nov 2026). The whole phrase found as typed
/// ranks first, then all-prefix matches, then typo matches.
int searchScore(String query, String text) {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) return 0;
  final t = text.toLowerCase();
  if (t.contains(q)) return t.startsWith(q) ? 4 : 3;
  final qWords = _words(q);
  final tWords = _words(t);
  if (qWords.isEmpty || tWords.isEmpty) return 0;
  var fuzzy = false;
  for (final w in qWords) {
    if (tWords.any((tw) => tw.startsWith(w) || (w.length >= 3 && tw.contains(w)))) {
      continue;
    }
    if (w.length >= 3 && tWords.any((tw) => _nearPrefix(w, tw))) {
      fuzzy = true;
      continue;
    }
    return 0;
  }
  return fuzzy ? 1 : 2;
}

List<String> _words(String s) =>
    s.split(RegExp(r"[^\p{L}\p{N}]+", unicode: true)).where((w) => w.isNotEmpty).toList();

/// True when [w] is within one edit of [tw] or of a prefix of it.
bool _nearPrefix(String w, String tw) {
  for (var len = w.length - 1; len <= w.length + 1; len++) {
    if (len < 2 || len > tw.length) continue;
    // A whole-word match may differ by one edit; a strict prefix must keep
    // the first letter (otherwise "ran" would match "Iran", "Bran…").
    if (len < tw.length && w[0] != tw[0]) continue;
    if (_lev1(w, tw.substring(0, len))) return true;
  }
  return false;
}

/// Edit distance ≤ 1 (one insertion, deletion or substitution).
bool _lev1(String a, String b) {
  if ((a.length - b.length).abs() > 1) return false;
  var i = 0, j = 0, edits = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }
    if (++edits > 1) return false;
    if (a.length > b.length) {
      i++;
    } else if (a.length < b.length) {
      j++;
    } else {
      i++;
      j++;
    }
  }
  return edits + (a.length - i) + (b.length - j) <= 1;
}

/// Ranks [items] by [searchScore] (best first, ties keep their order).
List<T> searchRank<T>(String query, List<T> items, String Function(T) text,
    {int limit = 12}) {
  final scored = <(T, int, int)>[];
  for (var i = 0; i < items.length; i++) {
    final sc = searchScore(query, text(items[i]));
    if (sc > 0) scored.add((items[i], sc, i));
  }
  scored.sort((a, b) => a.$2 != b.$2 ? b.$2 - a.$2 : a.$3 - b.$3);
  return [for (final s in scored.take(limit)) s.$1];
}

/// Shown before anything is typed: a few indicators people open most, and a
/// few countries.
const _popularSlugs = [
  'imf-gdp-per-capita-ppp',
  'wb-life-expectancy',
  'imf-inflation',
  'imf-population',
  'imf-unemployment',
  'whr-happiness',
];
const _popularIsos = ['USA', 'CHN', 'IND', 'DEU', 'BRA', 'PRT', 'JPN', 'NGA'];

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  String _q = '';
  List<Country> _countries = [];

  @override
  void initState() {
    super.initState();
    fetchCountryIndex().then((list) {
      list.sort((a, b) => a.name.compareTo(b.name));
      if (mounted) setState(() => _countries = list);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openCountry(Country c) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CountryPage(country: c, allCountries: _countries)));

  void _openDataset(CatalogEntry e) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => DatasetPage(entry: e)));

  Widget _sectionLabel(String text, {double top = 4}) => Padding(
        padding: EdgeInsets.fromLTRB(4, top, 4, 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: kAmberText)),
      );

  Widget _suggestions() {
    final bySlug = catalogBySlug;
    final indicators = [
      for (final s in _popularSlugs)
        if (bySlug[s] != null) bySlug[s]!
    ];
    final byIso = {for (final c in _countries) c.iso: c};
    final countries = [
      for (final iso in _popularIsos)
        if (byIso[iso] != null) byIso[iso]!
    ];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
          child: Text('Search countries and indicators — or start here:',
              style: TextStyle(color: kTextDim, fontSize: 13)),
        ),
        if (indicators.isNotEmpty) ...[
          _sectionLabel('POPULAR INDICATORS'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in indicators)
              ActionChip(
                avatar: Text((topicLabels[e.topic] ?? '📊').split(' ').first,
                    style: const TextStyle(fontSize: 14)),
                label: Text(e.title),
                onPressed: () => _openDataset(e),
              ),
          ]),
        ],
        if (countries.isNotEmpty) ...[
          _sectionLabel('COUNTRIES', top: 18),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in countries)
              ActionChip(
                avatar: Text(flagFromIso(c.iso),
                    style: const TextStyle(fontSize: 14)),
                label: Text(c.name),
                onPressed: () => _openCountry(c),
              ),
          ]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim();
    final countries = q.isEmpty
        ? const <Country>[]
        : searchRank(q, _countries, (c) => '${c.name} ${c.official} ${c.region}',
            limit: 8);
    final datasets = q.isEmpty
        ? const <CatalogEntry>[]
        : searchRank(q, catalog, (e) => '${e.title} ${e.source}');

    return Scaffold(
      appBar: AppBar(
        title: TextField(
              autocorrect: false,
              enableSuggestions: false,
          controller: _ctrl,
          autofocus: true,
          onChanged: (v) => setState(() => _q = v),
          style: const TextStyle(fontSize: 16),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Country or indicator…',
            hintStyle: TextStyle(color: kTextDim),
            border: InputBorder.none,
            suffixIcon: _q.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: Icon(Icons.close, color: kTextDim, size: 20),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() => _q = '');
                    },
                  ),
          ),
        ),
      ),
      body: q.isEmpty
          ? _suggestions()
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (countries.isNotEmpty) ...[
                  _sectionLabel('COUNTRIES'),
                  for (final c in countries)
                    ListTile(
                      dense: true,
                      leading: Text(flagFromIso(c.iso),
                          style: const TextStyle(fontSize: 20)),
                      title: Text(c.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(c.region,
                          style:
                              TextStyle(fontSize: 11, color: kTextDim)),
                      onTap: () => _openCountry(c),
                    ),
                ],
                if (datasets.isNotEmpty) ...[
                  _sectionLabel('INDICATORS', top: 12),
                  for (final e in datasets)
                    ListTile(
                      dense: true,
                      leading: Text(
                          (topicLabels[e.topic] ?? '📊').split(' ').first,
                          style: const TextStyle(fontSize: 18)),
                      title: Text(e.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(e.source,
                          style:
                              TextStyle(fontSize: 11, color: kTextDim)),
                      onTap: () => _openDataset(e),
                    ),
                ],
                if (countries.isEmpty && datasets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                        child: Text('Nothing found for “$q”.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kTextDim))),
                  ),
              ],
            ),
    );
  }
}
