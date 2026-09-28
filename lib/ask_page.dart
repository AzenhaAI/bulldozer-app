import 'widgets/shell_actions.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.dart';
import 'catalog_store.dart';
import 'charts_page.dart';
import 'countries_page.dart';
import 'flags.dart';
import 'theme.dart';

/// "Ask AI" — type a country, get what the catalogue holds on it and where it
/// stands out in the world, plus an answer in words from bot.azenha.ai/ask.
///
/// A tester asked for it. The written answer comes from a model (Claude, with
/// Workers AI as fallback) that is handed only this country's published
/// figures, and the server drops any answer containing a number those figures
/// do not hold. If there is no answer — offline, rate-limited, nothing that
/// passed the check — the brief below stands on its own, as it did before.
/// Every line of the brief is a published value with its year, rank
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
  final _qCtl = TextEditingController();
  String? _answer;
  bool _asking = false;
  String? _disclaimer; // "AI answers can be wrong", in the answer's language
  String? _askNote; // said aloud when no answer comes, instead of nothing

  static const _askUrl = 'https://bot.azenha.ai/ask';
  static const _suggestions = [
    'Summarise what stands out, in two sentences.',
    'How is the economy doing?',
    'How healthy is the population?',
  ];

  /// Asks the server; any failure leaves the brief to speak for itself.
  Future<void> _askAi(String iso, String q) async {
    setState(() {
      _asking = true;
      _answer = null;
      _disclaimer = null;
      _askNote = null;
    });
    try {
      final res = await http
          .post(Uri.parse(_askUrl),
              headers: {'content-type': 'application/json'},
              body: jsonEncode({'country': iso, 'q': q}))
          .timeout(const Duration(seconds: 45));
      if (res.statusCode == 200) {
        final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        if (mounted && _brief?.iso == iso) {
          setState(() {
            _answer = '${j['answer'] ?? ''}'.trim();
            _disclaimer = '${j['disclaimer'] ?? ''}'.trim();
          });
        }
      } else if (mounted) {
        // Silence read as "nothing happened". Say which of the two it was.
        setState(() => _askNote = res.statusCode == 429
            ? 'Too many questions in a minute — try again shortly. The figures below still stand.'
            : 'No answer passed the check against our figures this time. The figures below are the answer.');
      }
    } catch (_) {
      if (mounted) setState(() => _askNote = 'Could not reach the answer service. The figures below are from our data.');
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

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
    _qCtl.dispose();
    _ctl.dispose();
    super.dispose();
  }

  /// "kz уровень жизни", "Kazakhstan standard of living", "south africa gdp":
  /// a country at the start, a question after it. People type it in one go —
  /// the bot already takes "KZ gdp" — and a field that only understood a bare
  /// country simply did nothing.
  (Country, String)? get _countryAndQuestion {
    final raw = _query.trim();
    if (_countries == null || !raw.contains(' ')) return null;
    final words = raw.split(RegExp(r'\s+'));
    // Longest run of leading words that names a country wins, so "south
    // africa" beats "south".
    for (var n = words.length - 1; n >= 1; n--) {
      final head = words.take(n).join(' ').toLowerCase();
      final rest = words.skip(n).join(' ').trim();
      if (rest.isEmpty) continue;
      for (final c in _countries!) {
        if (c.iso.toLowerCase() == head ||
            iso2FromIso3(c.iso).toLowerCase() == head ||
            c.name.toLowerCase() == head) {
          return (c, rest);
        }
      }
    }
    return null;
  }

  List<Country> get _matches {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty || _countries == null) return const [];
    // "kz" and "kaz" work as well as "Kazakhstan"; an exact code comes first,
    // so "de" is Germany rather than every name containing "de".
    bool code(Country c) => c.iso.toLowerCase() == q || iso2FromIso3(c.iso).toLowerCase() == q;
    final exact = _countries!.where(code).toList();
    final byName = _countries!.where((c) =>
        !code(c) && (c.name.toLowerCase().contains(q) || c.official.toLowerCase().contains(q)));
    return [...exact, ...byName].take(8).toList();
  }

  Future<void> _ask(Country c, [String? question]) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _brief = null;
      _answer = null;
      _qCtl.clear();
      _query = '';
      _ctl.text = c.name;
    });
    try {
      final j = await fetchJson('/data/brief/${c.iso.toLowerCase()}.json');
      if (mounted) setState(() => _brief = _Brief.fromJson(j as Map<String, dynamic>));
      // The summary the tester asked for, without having to ask for it — or
      // the question typed after the country, if there was one.
      if (mounted) {
        if (question != null) _qCtl.text = question;
        _askAi(c.iso, question ?? _suggestions.first);
      }
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
            child: Text('BETA',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: kAmber)),
          ),
          const Spacer(),
          const ShellActions(),
        ]),
        const SizedBox(height: 6),
        Text(
            'Type a country or its code (kz, kaz) — or a country and a question, '
            'like "kz standard of living". Answers use only our published figures, and any number '
            'not found in them is held back. Your question and the country code go to our server '
            'and to Anthropic to phrase the answer. AI answers can be wrong — the figures are the source.',
            style: TextStyle(fontSize: 13, color: kTextDim, height: 1.4)),
        const SizedBox(height: 14),
        TextField(
          controller: _ctl,
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _query = v),
          onSubmitted: (_) {
            final cq = _countryAndQuestion;
            if (cq != null) {
              _ask(cq.$1, cq.$2);
              return;
            }
            final m = _matches;
            if (m.isNotEmpty) _ask(m.first);
          },
          decoration: InputDecoration(
            hintText: 'A country or code — Kazakhstan, kz, BRA',
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
        if (_countryAndQuestion case (final c, final q))
          ListTile(
            dense: true,
            leading: Text(flagFromIso(c.iso), style: const TextStyle(fontSize: 20)),
            title: Text('Ask about ${c.name}'),
            subtitle: Text('“$q”', style: TextStyle(color: kTextDim, fontSize: 12)),
            trailing: Icon(Icons.send_outlined, color: kAmber, size: 20),
            onTap: () => _ask(c, q),
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
        if (_brief != null) ..._answerBlock(_brief!),
      ],
    );
  }

  List<Widget> _answerBlock(_Brief b) {
    final country = _countries?.where((c) => c.iso == b.iso).firstOrNull;
    return [
      const SizedBox(height: 18),
      Text('${flagFromIso(b.iso)}  ${b.name}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      if (_asking)
        const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: LinearProgressIndicator(minHeight: 2)),
      if (_answer != null && _answer!.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kAmber.withValues(alpha: 0.5))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI ANSWER · FIGURES CHECKED AGAINST OUR DATA',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: kAmber)),
            const SizedBox(height: 8),
            SelectableText(_answer!, style: const TextStyle(fontSize: 15, height: 1.45)),
            const SizedBox(height: 8),
            Text(
                (_disclaimer?.isNotEmpty ?? false)
                    ? _disclaimer!
                    : 'AI answers can be wrong — the figures below are the source.',
                style: TextStyle(fontSize: 12, color: kTextDim, fontStyle: FontStyle.italic)),
          ]),
        ),
      if (_askNote != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(_askNote!, style: TextStyle(fontSize: 13, color: kTextDim, fontStyle: FontStyle.italic)),
        ),
      const SizedBox(height: 12),
      TextField(
        controller: _qCtl,
        maxLength: 300,
        textInputAction: TextInputAction.send,
        onChanged: (_) => setState(() {}), // wakes the send button
        onSubmitted: (v) {
          if (v.trim().isNotEmpty && !_asking) _askAi(b.iso, v.trim());
        },
        decoration: InputDecoration(
          hintText: 'Ask about ${b.name}…',
          counterText: '',
          isDense: true,
          filled: true,
          fillColor: kBgCard,
          suffixIcon: IconButton(
            icon: const Icon(Icons.send_outlined),
            onPressed: _asking || _qCtl.text.trim().isEmpty ? null : () => _askAi(b.iso, _qCtl.text.trim()),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder, width: 0.5)),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final s in _suggestions.skip(1))
          ActionChip(
            label: Text(s, style: const TextStyle(fontSize: 12)),
            onPressed: _asking ? null : () { _qCtl.text = s; _askAi(b.iso, s); },
          ),
      ]),
      ..._facts(b, country),
    ];
  }

  List<Widget> _facts(_Brief b, Country? country) {
    return [
      const SizedBox(height: 18),
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
