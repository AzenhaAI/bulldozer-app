import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

/// AI news, long reads on AI and the week's papers, under Ask AI.
///
/// Testers asked for news about AI and for writing that thinks about it
/// (R11, 24 Oct 2026). The list is built by bot.azenha.ai/ai-news from the
/// publishers' own feeds — labs, the press desks that cover them, alignment
/// and philosophy-of-AI writing, and the Hugging Face weekly paper ranking —
/// and carries titles and links only: every row opens the publisher.
/// Best-effort: with no connection the block simply is not there.
class AiReading extends StatefulWidget {
  const AiReading({super.key});

  @override
  State<AiReading> createState() => _AiReadingState();
}

class _Item {
  final String title, link, source, date;
  _Item(Map<String, dynamic> j)
      : title = '${j['title'] ?? ''}',
        link = '${j['link'] ?? ''}',
        source = '${j['source'] ?? ''}',
        date = '${j['date'] ?? ''}';
}

class _Section {
  final String id, title;
  final List<_Item> items;
  _Section(Map<String, dynamic> j)
      : id = '${j['id'] ?? ''}',
        title = '${j['title'] ?? ''}',
        items = [for (final i in (j['items'] as List? ?? [])) _Item(i as Map<String, dynamic>)];
}

class _AiReadingState extends State<AiReading> {
  static List<_Section>? _cache; // one fetch per app run is plenty
  List<_Section>? _sections = _cache;
  int _tab = 0;
  bool _all = false;

  @override
  void initState() {
    super.initState();
    if (_sections == null) _load();
  }

  Future<void> _load() async {
    try {
      final r = await http.get(Uri.parse('https://bot.azenha.ai/ai-news')).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return;
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final s = [
        for (final x in (j['sections'] as List? ?? [])) _Section(x as Map<String, dynamic>)
      ].where((x) => x.items.isNotEmpty).toList();
      if (s.isEmpty) return;
      _cache = s;
      if (mounted) setState(() => _sections = s);
    } catch (_) {
      // offline or the list is down — Ask AI works without it
    }
  }

  String _ago(String iso) {
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    final d = DateTime.now().toUtc().difference(t.toUtc());
    if (d.inHours < 1) return 'just now';
    if (d.inHours < 24) return '${d.inHours} h ago';
    if (d.inDays < 7) return '${d.inDays} d ago';
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    // Karpathy's tab reaches back years; a date without one would mislead.
    return t.year == DateTime.now().year ? '${t.day} ${m[t.month - 1]}' : '${m[t.month - 1]} ${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    if (sections == null || sections.isEmpty) return const SizedBox.shrink();
    final s = sections[_tab.clamp(0, sections.length - 1)];
    final shown = _all ? s.items : s.items.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Text('READ ABOUT AI',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: kAmber)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < sections.length; i++)
            ChoiceChip(
              label: Text(sections[i].title),
              selected: i == _tab,
              onSelected: (_) => setState(() {
                _tab = i;
                _all = false;
              }),
            ),
        ]),
        const SizedBox(height: 6),
        for (final it in shown)
          InkWell(
            onTap: () => launchUrl(Uri.parse(it.link), mode: LaunchMode.inAppBrowserView),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(it.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3)),
                    const SizedBox(height: 3),
                    Text([it.source, _ago(it.date)].where((x) => x.isNotEmpty).join(' · '),
                        style: TextStyle(fontSize: 12, color: kTextDim)),
                  ]),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Icon(Icons.north_east, color: kTextDim, size: 15),
                ),
              ]),
            ),
          ),
        if (s.items.length > 5)
          TextButton(
            onPressed: () => setState(() => _all = !_all),
            child: Text(_all ? 'Show fewer' : 'Show all ${s.items.length}'),
          ),
        Text('Headlines and links from the publishers’ own feeds; tap to read at the source.',
            style: TextStyle(fontSize: 11, color: kTextDim, height: 1.4)),
      ],
    );
  }
}
