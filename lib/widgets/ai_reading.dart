import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
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
  // Kept between visits, but not for the whole run: an app left open for a day
  // never saw the Images & video tab added on the server (28 Oct 2026).
  static List<_Section>? _cache;
  static DateTime? _cachedAt;
  List<_Section>? _sections = _cache;
  int _tab = 0;
  bool _failed = false; // shown with Retry: a block that silently vanished hid a network fault (28 Oct)
  bool _all = false;

  @override
  void initState() {
    super.initState();
    final stale = _cachedAt == null || DateTime.now().difference(_cachedAt!) > const Duration(minutes: 30);
    if (_sections == null || stale) _load();
  }

  Future<void> _load() async {
    if (_failed && mounted) setState(() => _failed = false);
    try {
      final r = await http.get(Uri.parse('https://bot.azenha.ai/ai-news')).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final s = [
        for (final x in (j['sections'] as List? ?? [])) _Section(x as Map<String, dynamic>)
      ].where((x) => x.items.isNotEmpty).toList();
      if (s.isEmpty) throw Exception('empty list');
      _cache = s;
      _cachedAt = DateTime.now();
      if (mounted) setState(() => _sections = s);
    } catch (_) {
      // Ask AI works without it; say so instead of leaving a gap.
      if (mounted && _sections == null) setState(() => _failed = true);
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
    if (sections == null || sections.isEmpty) {
      if (!_failed) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Row(children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: kTextDim),
          const SizedBox(width: 8),
          Expanded(
              child: Text("Couldn't load the AI reading list. Check the connection.",
                  style: TextStyle(fontSize: 13, color: kTextDim))),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
    }
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
        if (s.id == 'media')
          // Testers asked for image and video AI as more than headlines (R13).
          TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: kAmber),
            onPressed: () => launchUrl(Uri.parse(inAppSite('$kSiteUrl/edu/ai-media/')),
                mode: LaunchMode.inAppBrowserView),
            icon: const Icon(Icons.school_outlined, size: 18),
            label: const Text('New to this? Our guide: tools, free options, licences, labelling rules'),
          ),
        Text('Headlines and links from the publishers’ own feeds; tap to read at the source.',
            style: TextStyle(fontSize: 11, color: kTextDim, height: 1.4)),
      ],
    );
  }
}
