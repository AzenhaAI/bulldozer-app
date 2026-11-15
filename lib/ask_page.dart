import 'widgets/shell_actions.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'catalog_store.dart';
import 'charts_page.dart';
import 'countries_page.dart';
import 'flags.dart';
import 'theme.dart';
import 'widgets/ai_reading.dart';

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

  /// Per standout slug (for the brief on screen): how many other countries
  /// share its exact value in that period, and whether that value is the
  /// world's maximum/minimum. The brief gives tied countries the same rank, so
  /// "#1 of 214" for electricity at 100% was 1 of 121 at 100% (reviewers,
  /// 15 Nov 2026) — read from the dataset itself, best-effort.
  final Map<String, ({int others, bool extreme})> _ties = {};
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
    if (!await _aiConsent()) {
      if (mounted) setState(() => _askNote = 'Nothing was sent. The figures below are from our data.');
      return;
    }
    if (!mounted) return;
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

  static const _kAiConsent = 'ask.ai.consent';

  /// Asked once, before the first question leaves the phone (App Store
  /// guideline 5.1.2(i)): what goes where, in plain words, with a real way to
  /// say no. Declining keeps the figures and sends nothing.
  Future<bool> _aiConsent() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kAiConsent) ?? false) return true;
    if (!mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgElev,
        title: Text('Send this question to an AI?', style: TextStyle(color: kText, fontSize: 18)),
        content: Text(
          'To write the answer in words, your question and the country you picked are sent '
          'to our server and on to Claude, an AI model by Anthropic (or, if it is unavailable, '
          'a model on Cloudflare). Nothing that identifies you is sent, and we keep no record '
          'of it. The figures on this screen do not need this.',
          style: TextStyle(color: kTextDim, height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Allow')),
        ],
      ),
    );
    // The closing dialog hands focus back to the country field once its exit
    // transition ends, which would bring the keyboard back. Drop it after that.
    Future.delayed(const Duration(milliseconds: 400), () => FocusManager.instance.primaryFocus?.unfocus());
    if (ok == true) await prefs.setBool(_kAiConsent, true);
    return ok == true;
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
      if (mounted) {
        final brief = _Brief.fromJson(j as Map<String, dynamic>);
        setState(() {
          _brief = brief;
          _ties.clear();
        });
        _loadTies(brief);
      }
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
        // Nothing matched: say so. A typo ("z is it safe") used to leave an
        // empty screen, which reads as the feature not working.
        if (_countries != null &&
            _query.trim().length >= 2 &&
            _countryAndQuestion == null &&
            _matches.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
                'No country matches “${_query.trim()}”. Start with a country or its code, '
                'then the question — for example “kz is it safe?”',
                style: TextStyle(color: kTextDim, fontSize: 13, height: 1.4)),
          ),
        if (_loading)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!, style: TextStyle(color: kTextDim))),
        if (_brief != null) ..._answerBlock(_brief!),
        const SizedBox(height: 28),
        GuideBanner.modelLab,
        const SizedBox(height: 10),
        GuideBanner.aiMedia,
        const AiReading(),
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

  Future<void> _loadTies(_Brief b) async {
    for (final s in b.standouts) {
      final slug = '${s['slug']}';
      final v = (s['value'] as num?)?.toDouble();
      if (v == null) continue;
      fetchDataset(slug).then((ds) {
        if (!mounted || _brief != b) return;
        final t = standoutTie(ds, '${s['period']}', v, '${s['side']}', b.iso);
        if (t != null) setState(() => _ties[slug] = t);
      }).catchError((_) {});
    }
  }

  /// "#4 of 179 — among the highest in the world", or, when the value is the
  /// world's ceiling shared by many, "at the maximum, shared with 120 other
  /// countries" — a tie is not a record.
  String _standing(Map<String, dynamic> s) {
    final high = s['side'] == 'high';
    final t = _ties['${s['slug']}'];
    if (t != null && t.others > 0) {
      final n = '${t.others} other ${t.others == 1 ? 'country' : 'countries'}';
      if (t.extreme) return 'at the ${high ? 'maximum' : 'minimum'}, shared with $n';
      return '#${s['rank']} of ${s['total']}, tied with $n — among the ${high ? 'highest' : 'lowest'} in the world';
    }
    return '#${s['rank']} of ${s['total']} — among the ${high ? 'highest' : 'lowest'} in the world';
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
                '${_standing(s)}\n'
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

/// A guide on azenha.ai, shown as a card at the foot of Ask AI.
///
/// Model Lab: 22 open models tested on an ordinary 16 GB laptop against the
/// cloud — the next step for anyone who wants to run AI themselves. The images
/// and video guide sat only inside its tab of the reading list, and testers
/// looking for it did not find it (2 Nov 2026), so it has a card of its own.
class GuideBanner extends StatelessWidget {
  final String emoji, title, text, url;
  const GuideBanner(this.emoji, this.title, this.text, this.url, {super.key});

  static const modelLab = GuideBanner(
      '💻',
      'Run AI on your own laptop',
      'We tested 22 open models on an ordinary 16 GB MacBook against the cloud — '
          'which ones fit and answer well. A guide for students on a modest computer.',
      'https://azenha.ai/modellab/');

  static const aiMedia = GuideBanner(
      '🎬',
      'Make images and video with AI',
      'Which generators are free, which open models run on your own computer, '
          'licences and the new labelling rules — a student\'s map, every fact linked.',
      '$kSiteUrl/edu/ai-media/');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => launchUrl(Uri.parse(inAppSite(url)), mode: LaunchMode.inAppBrowserView),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder, width: 0.5)),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(text, style: TextStyle(fontSize: 13, color: kTextDim, height: 1.4)),
            ]),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward, color: kAmber, size: 20),
        ]),
      ),
    );
  }
}

/// How many countries other than [iso] share [value] in [period] of [ds]
/// (each country's latest reading when the period has none), and whether
/// that value is the extreme on [side] ('high' → maximum, 'low' → minimum).
/// Null when the dataset has no readings to compare.
({int others, bool extreme})? standoutTie(
    Dataset ds, String period, double value, String side, String iso) {
  final byIso = <String, Observation>{};
  for (final o in ds.data) {
    if (o.iso.isEmpty || !o.value.isFinite) continue;
    if (o.period == period) byIso[o.iso] = o;
  }
  if (byIso.isEmpty) {
    for (final o in ds.data) {
      if (o.iso.isEmpty || !o.value.isFinite) continue;
      final cur = byIso[o.iso];
      if (cur == null || o.period.compareTo(cur.period) > 0) byIso[o.iso] = o;
    }
  }
  if (byIso.isEmpty) return null;
  final tol = 1e-6 * (value.abs() > 1 ? value.abs() : 1);
  var others = 0;
  var hi = double.negativeInfinity, lo = double.infinity;
  for (final e in byIso.entries) {
    final x = e.value.value;
    if (x > hi) hi = x;
    if (x < lo) lo = x;
    if (e.key != iso && (x - value).abs() <= tol) others++;
  }
  final extreme = side == 'low' ? value <= lo + tol : value >= hi - tol;
  return (others: others, extreme: extreme);
}
