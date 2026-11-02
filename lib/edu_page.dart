import 'widgets/shell_actions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'map_maker_page.dart';
import 'people_chart_page.dart';
import 'theme.dart';

/// Edu tab — mirrors the site's /edu section: a field guide to dashboards,
/// BI-tool comparison, how the pipeline works and curated places to learn.
/// Content lives on the site; cards deep-link into its anchored sections.
class EduPage extends StatelessWidget {
  const EduPage({super.key});

  void _open(String path) {
    // Absolute links (Model Lab lives outside the BullDozer section) go as is.
    final url = path.startsWith('http') ? path : '$kSiteUrl$path';
    launchUrl(Uri.parse(inAppSite(url)), mode: LaunchMode.inAppBrowserView);
  }

  @override
  Widget build(BuildContext context) {
    const sections = <(String, String, String, String)>[
      (
        '📊',
        'A field guide to dashboards',
        'Six kinds of dashboard — KPI, operational, analytical, strategic, data story, geospatial — and when to use each.',
        '/edu/#types',
      ),
      (
        '🛠️',
        'BI tools, honestly compared',
        'Tableau, Power BI, Looker Studio, Metabase, Superset and friends — strengths, limits, pricing.',
        '/edu/#tools',
      ),
      (
        '⚙️',
        'How BullDozer is built',
        'Parse → normalise → publish: the open pipeline behind every chart in this app.',
        '/edu/#pipeline',
      ),
      (
        '🎓',
        'Free places to learn',
        'Dataviz craft, SQL practice, scraping and the best public data journalism, hand-picked.',
        '/edu/#learn',
      ),
      (
        '🗂️',
        'Sources — the world\'s surveys and data',
        '81 research programmes, from the World Values Survey to PISA and Gallup — what each covers, how to get it, and which ones this app uses.',
        '/edu/sources/',
      ),
      (
        '🎬',
        'Images and video with AI',
        'A student\'s map: cloud generators and open models you can run yourself, what is free, '
            'whose licence lets you publish, and the EU\'s labelling rules — every fact sourced.',
        '/edu/ai-media/',
      ),
      (
        '💻',
        'AI on a student laptop',
        '22 open language models on one ordinary 16 GB MacBook, the same 24 questions in seven languages, compared with the cloud.',
        'https://azenha.ai/modellab/',
      ),
      (
        '📖',
        'Glossary — metric reference',
        'What GDP PPP, Gini, HDI, polyarchy and every other metric in the app actually mean.',
        '/glossary/',
      ),
    ];

    // Eight links and nothing else — this is the one tab a wide layout cannot
    // help. Stretched to the full 1280 the cards became long thin strips over a
    // field of empty black; held to a reading column they read as a deliberate
    // index, which is what they are. The rest of the app fills the width; this
    // page earns its margins.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(child: Text('Edu', style: pageTitleStyle)),
          const ShellActions(),
        ]),
        const SizedBox(height: 4),
        Text('Learn to read — and build — data like this.',
            style: TextStyle(fontSize: 12, color: kTextDim)),
        const SizedBox(height: 14),
        // Tools that run in the app, ahead of the reading list. Testers asked
        // for poster maps (R10) and people charts (R14); more makers join as they ship.
        Text('MAKE YOUR OWN',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: kAmber)),
        const SizedBox(height: 6),
        for (final m in <(String, String, String, Widget Function())>[
          (
            '🗺️',
            'Map maker',
            'Turn any of our indicators into a poster map: pick a region, '
                'name the colour classes, share the image — with its source on it.',
            () => const MapMakerPage(),
          ),
          (
            '🧍',
            'People chart',
            'Columns of 100 figures: compare countries on one question or on '
                'what people die of, or draw your own table.',
            () => const PeopleChartPage(),
          ),
        ])
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => m.$4())),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.$1, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.$2,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.2)),
                          const SizedBox(height: 4),
                          Text(m.$3, style: TextStyle(fontSize: 12, color: kTextDim, height: 1.35)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6, top: 2),
                      child: Icon(Icons.chevron_right, color: kTextDim, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text('READ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: kAmber)),
        const SizedBox(height: 6),
        for (final s in sections)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              onTap: () => _open(s.$4),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.$1, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$2,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2)),
                          const SizedBox(height: 4),
                          Text(s.$3,
                              style: TextStyle(
                                  fontSize: 12, color: kTextDim, height: 1.35)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 6, top: 2),
                      child: Icon(Icons.north_east, color: kTextDim, size: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        // The images and video guide as a thin strip at the very end, where a
        // reader who scrolled the whole tab lands — so it is not lost in the
        // list above (2 Nov 2026).
        Material(
          color: kAmber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _open('/edu/ai-media/'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                const Text('🎬', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                const Expanded(
                    child: Text('Make images and video with AI — free tools, licences, labelling',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                Icon(Icons.arrow_forward, color: kAmber, size: 18),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text('Reads on the site · azenha.ai/bulldozer/edu',
              style: TextStyle(fontSize: 11, color: kTextDim)),
        ),
      ],
        ),
      ),
    );
  }
}
