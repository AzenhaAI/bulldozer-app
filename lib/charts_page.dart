import 'widgets/shell_actions.dart';
import 'package:flutter/material.dart';

import 'api.dart';
import 'catalog_store.dart';
import 'favorites_store.dart';
import 'responsive.dart';
import 'share_card.dart';
import 'flags.dart';
import 'theme.dart';
import 'search_page.dart' show searchScore;
import 'widgets/sample_stats.dart';
import 'widgets/load_error.dart';
import 'widgets/choropleth.dart';
import 'widgets/entrance.dart';
import 'widgets/featured_card.dart';
import 'brands_page.dart';
import 'csv_export.dart';
import 'cultural_map_page.dart';
import 'explore_page.dart';
import 'widgets/freshness.dart';
import 'widgets/hero_extras.dart';
import 'widgets/skeleton.dart';
import 'widgets/trend_chart.dart';
import 'usage.dart';

// Topic taxonomy mirrors the site's lib/topics.ts
/// Alphabetical key for a topic — the display label without its emoji prefix.
String topicSortKey(String t) =>
    (topicLabels[t] ?? t).replaceFirst(RegExp(r'^\S+\s'), '');

/// Fixed display order (site's TOPIC_ORDER): Economy, Demographics,
/// Connectivity first, then the rest.
const topicOrder = [
  'economy', 'demographics', 'connectivity', 'health', 'education',
  'environment', 'governance', 'media', 'safety', 'risk', 'wellbeing',
  'attitudes',
];
int topicRank(String t) {
  final i = topicOrder.indexOf(t);
  return i < 0 ? topicOrder.length : i;
}

const topicLabels = {
  'attitudes': '🧭 Attitudes & values',
  'connectivity': '🌐 Connectivity',
  'demographics': '👥 Demographics',
  'economy': '📈 Economy',
  'education': '🎓 Education',
  'environment': '🌱 Environment',
  'governance': '🏛️ Governance',
  'health': '🫀 Health',
  'media': '📰 Media & news',
  'risk': '⚠️ Risk & resilience',
  'safety': '🛡️ Safety',
  'wellbeing': '😊 Wellbeing',
};

/// The site's Biz section (/markets): markets + financial-access indicators.
const bizSlugs = [
  'wb-market-cap',
  'forbes-global-2000',
  'brandz-value',
  'brandz-count',
  'wb-stocks-traded',
  'wb-listed-companies',
  'wb-account-ownership',
  'findex-digital-payments', // WB's own series ends in 2017; Findex runs to 2024
  'wb-mobile-money',
  'wb-debit-card',
  'wb-bank-branches',
];

/// One dataset list tab. Mirrors the site's sections: kind 'macro' →
/// Statistics (/macro), kind 'survey' → Polls (/surveys), or an explicit
/// curated [slugs] list → Biz (/markets).
class ChartsPage extends StatefulWidget {
  final String title;
  final String? kind; // 'macro' | 'survey'
  final List<String>? slugs; // curated set, overrides kind (Biz)
  final String? featuredSlug; // dataset shown as a featured hero on top
  final String featuredStyle; // 'bars' | 'trend' | 'dots' — distinct per tab
  final List<Widget> topCards; // entry cards above the list (e.g. Biz brands)
  const ChartsPage(
      {super.key,
      required this.title,
      this.kind,
      this.slugs,
      this.featuredSlug,
      this.featuredStyle = 'bars',
      this.topCards = const []});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  String _query = '';
  final _searchCtl = TextEditingController();
  String _topic = 'all';
  List<Observation> _featTop = [];
  Dataset? _featDs; // full dataset, for the trend/dots hero styles
  List<Brand> _brands = []; // top brands, for the Biz podium hero
  List<RecordFact> _records = []; // world-records facts, for the Stats hero

  // Rotating pool for the records hero: emoji, caption, slug, best=max|min.
  static const _recordPool = <(String, String, String, bool)>[
    ('👴', 'longest life expectancy', 'wb-life-expectancy', true),
    ('👥', 'most people', 'imf-population', true), // Gapminder's ends in 2013
    ('📈', 'fastest GDP growth', 'imf-gdp-growth', true),
    ('💰', 'richest per capita (PPP)', 'imf-gdp-per-capita-ppp', true),
    ('🌐', 'most internet users', 'gapminder-internet', true),
    ('🏭', 'highest CO₂ per capita', 'wb-en-ghg-co2-pc-ce-ar5', true),
    ('🎓', 'most years of schooling', 'owid-schooling', true),
    ('🔥', 'highest inflation', 'imf-inflation', true),
    ('🕊️', 'lowest homicide rate', 'gapminder-homicide', false),
  ];

  Future<void> _loadRecords() async {
    // shuffle the whole pool on every visit — 7 facts, fresh order each time
    final picks = [..._recordPool]..shuffle();
    picks.length = 5;
    final out = <RecordFact>[];
    for (final p in picks) {
      try {
        final ds = await fetchDataset(p.$3);
        // A record is a fact: the last observed year, never an IMF forecast.
        final last = ds.lastObserved ?? ds.periods.last;
        final rows = ds.data
            .where((o) => o.period == last && o.iso.isNotEmpty)
            .toList()
          ..sort((a, b) =>
              p.$4 ? b.value.compareTo(a.value) : a.value.compareTo(b.value));
        if (rows.isEmpty) continue;
        final o = rows.first;
        // A record needs its year: IMF series end in the IMF's own projection
        // for the current year, so "highest inflation" was a 2026 forecast
        // presented as a fact. And a tie is not a record: three countries
        // stand at 100% internet use, and one of them was named the leader.
        final ties = rows.where((r) => r.value == o.value).length;
        final y = int.tryParse(RegExp(r'\d{4}').stringMatch(last) ?? '') ?? 0;
        // An estimate only where the series says the projection starts.
        final pf = ds.projectedFrom;
        final est = pf != null && y >= pf;
        final when = est ? '$last est.' : last;
        out.add(RecordFact(
            emoji: p.$1,
            country: ties > 1 ? '${o.entity} +${ties - 1}' : o.entity,
            iso: o.iso,
            caption: ties > 1 ? '${p.$2} · tied by $ties' : p.$2,
            when: when,
            value: formatWithUnit(o.value, ds.unit),
            slug: p.$3));
      } catch (_) {}
    }
    if (mounted && out.isNotEmpty) setState(() => _records = out);
  }

  @override
  void initState() {
    super.initState();
    _loadFeatured();
    if (widget.featuredStyle == 'records') _loadRecords();
    if (widget.featuredStyle == 'podium') {
      fetchBrands().then((b) {
        b.sort((x, y) => x.rank.compareTo(y.rank));
        if (mounted) setState(() => _brands = b.take(3).toList());
      }).catchError((_) {});
    }
  }

  Future<void> _loadFeatured() async {
    final slug = widget.featuredSlug;
    if (slug == null) return;
    try {
      final ds = await fetchDataset(slug);
      final last = ds.lastObserved ?? ds.periods.last;
      final rows = ds.data.where((o) => o.period == last).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (mounted) {
        setState(() {
          _featDs = ds;
          _featTop = rows.take(6).toList();
        });
      }
    } catch (_) {
      // hero is decorative
    }
  }

  /// The median country per period over a fixed panel (countries present in
  /// every year), so the line moves because countries moved, not because the
  /// set of reporters changed. It was a plain mean of whoever reported,
  /// labelled "WORLD" (statistical review, 15 Nov 2026).
  ({List<(String, double)> points, int n})? _worldMedian() {
    final ds = _featDs;
    if (ds == null) return null;
    final pm = ds.panelMedians();
    if (pm == null || pm.points.length < 2) return null;
    return pm;
  }

  /// The wide-screen companion for a hero that is a snapshot: where the
  /// snapshot says who leads today, this says which way the world has moved.
  /// Null when the dataset has a single period, and the ranking runs instead.
  Widget? _trendCompanion(CatalogEntry e) {
    final wm = _worldMedian();
    if (wm == null) return null;
    final avg = wm.points;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MEDIAN OF ${wm.n} COUNTRIES · ${e.title.toUpperCase()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: kTextDim)),
        const SizedBox(height: 2),
        Text(
            '${formatValue(avg.first.$2)} → ${formatValue(avg.last.$2)}'
            '  ·  ${avg.first.$1}–${avg.last.$1}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TrendChart(
            points: avg, highlightPeriod: avg.last.$1, height: 170),
      ],
    );
  }

  /// Distinct hero per tab: Stats a world trend line, Biz a brand podium,
  /// Polls a world-average gauge — no more identical "mattresses".
  Widget _buildHero(CatalogEntry featEntry) {
    void onTap() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DatasetPage(entry: featEntry)));

    /// Pairs a hero visual with the featured dataset's leaderboard when the
    /// screen is wide enough. On a phone these heroes fill the card; on a
    /// tablet each one was a small graphic with a field of empty card beside
    /// it, so the ranking the site always shows alongside comes back.
    Widget paired(Widget visual, String caption,
        {int flexA = 3, Widget? companion}) {
      if (!isWide(context) || (companion == null && _featTop.isEmpty)) {
        return visual;
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: flexA, child: visual),
          const SizedBox(width: 18),
          Expanded(
            flex: 2,
            child: companion ??
                RankBars(
                  rows: _featTop,
                  caption: caption,
                  onTap: (iso) {
                    final e = catalogBySlug[widget.featuredSlug];
                    if (e != null) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => DatasetPage(entry: e)));
                    }
                  },
                ),
          ),
        ],
      );
    }

    if (widget.featuredStyle == 'podium' && _brands.length >= 3) {
      return HeroShell(
        tag: 'Most valuable brands',
        title: '${_brands.first.name} — the world’s top brand',
        footer:
            'All 96 brands with logos → · values: Kantar BrandZ / Forbes',
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const BrandsPage())),
        child: paired(BrandPodium(top3: _brands), featEntry.title, flexA: 2),
      );
    }
    if (widget.featuredStyle == 'records' && _records.isNotEmpty) {
      return HeroShell(
        tag: 'World records',
        title: 'The world in superlatives',
        footer: 'Tap a record for the full ranking →',
        onTap: onTap,
        chipLabel: 'Bivariate map',
        chipIcon: Icons.grid_view,
        onChipTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ExplorePage())),
        child: paired(
          RecordsHero(
            facts: _records,
            onTapFact: (f) {
              final e = catalogBySlug[f.slug];
              if (e != null) {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DatasetPage(entry: e)));
              }
            },
          ),
          featEntry.title,
          companion: _trendCompanion(featEntry),
        ),
      );
    }
    if (widget.featuredStyle == 'cultural') {
      return HeroShell(
        tag: 'World Values Survey',
        title: 'The Inglehart–Welzel map of values',
        footer: 'Explore the map — tap any country →',
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CulturalMapPage())),
        child: paired(const MiniCulturalMap(), featEntry.title),
      );
    }
    if (widget.featuredStyle == 'gauge' && _featDs != null) {
      final last = _featDs!.periods.last;
      final rows = _featDs!.data.where((o) => o.period == last).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (rows.length >= 2) {
        final avg =
            rows.map((o) => o.value).reduce((a, b) => a + b) / rows.length;
        return HeroShell(
          tag: 'Featured · ${featEntry.source}',
          title: featEntry.title,
          footer: 'See every country →',
          onTap: onTap,
          child: paired(
              GaugeHero(avg: avg, top: rows.first, low: rows.last),
              featEntry.title),
        );
      }
    }
    if (widget.featuredStyle == 'trend' && _featDs != null) {
      // Median of the same countries in every period: an average over whoever
      // reported each year showed who was surveyed, not change.
      final panel = _featDs!.panelMedians();
      final avg = panel?.points ?? const <(String, double)>[];
      if (avg.length >= 2) {
        return HeroShell(
          tag: 'Featured · ${featEntry.source}',
          title: '${featEntry.title}, median of ${panel!.n} countries: '
              '${formatValue(avg.first.$2)} → ${formatValue(avg.last.$2)}',
          footer: 'See the full ranking →',
          onTap: onTap,
          child: TrendChart(
              points: avg,
              highlightPeriod: avg.last.$1,
              height: 140,
              unit: _featDs!.unit,
              mode: _featDs!.changeMode.isEmpty ? null : _featDs!.changeMode,
              projectedFrom: _featDs!.projectedFrom),
        );
      }
    }
    if (widget.featuredStyle == 'dots' && _featDs != null) {
      final last = _featDs!.periods.last;
      final rows = _featDs!.data.where((o) => o.period == last).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return HeroShell(
        tag: 'Featured · ${featEntry.source}',
        title: '${_featTop.first.entity} leads — ${featEntry.title}',
        footer: 'Every dot is a country · see them all →',
        onTap: onTap,
        child: DotStrip(items: [
          for (final o in rows)
            ('${flagFromIso(o.iso)} ${o.entity}', o.value, o.group)
        ]),
      );
    }
    return FeaturedCard(
      tag: 'Featured · ${featEntry.source}',
      title: '${_featTop.first.entity} tops ${featEntry.title}',
      bars: [
        for (final o in _featTop)
          ('${flagFromIso(o.iso)} ${o.entity}', o.value)
      ],
      footer: 'See the full ranking →',
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pool = widget.slugs != null
        ? widget.slugs!
            .map((s) => catalogBySlug[s])
            .whereType<CatalogEntry>()
            .toList()
        : catalog.where((e) => e.kind == widget.kind).toList();
    final q = _query.toLowerCase();
    final shown = pool
        .where((e) => _topic == 'all' || e.topic == _topic)
        // Word-start and one-typo matching, as in the main search: "without
        // food" missed "Went Without Enough Food" (QA, 15 Nov 2026).
        .where((e) => q.isEmpty || searchScore(q, '${e.title} ${e.source}') > 0)
        .toList();
    final topics = {for (final e in pool) e.topic}.toList()
      ..sort((a, b) => topicRank(a).compareTo(topicRank(b)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Expanded(child: Text(widget.title, style: pageTitleStyle)),
            const ShellActions(),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtl,
            onChanged: (v) => setState(() => _query = v),
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: Icon(Icons.close, color: kTextDim, size: 18),
                      onPressed: () => setState(() {
                        _searchCtl.clear();
                        _query = '';
                      }),
                    ),
              hintText: 'Search ${pool.length} indicators…',
              hintStyle: TextStyle(color: kTextDim, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: kTextDim, size: 20),
              isDense: true,
              filled: true,
              fillColor: kBgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: kBorder, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: kBorder, width: 0.5),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              for (final t in ['all', ...topics])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(t == 'all' ? 'All' : topicLabels[t] ?? t),
                    selected: _topic == t,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _topic == t ? kOnAmber : kText),
                    onSelected: (_) => setState(() => _topic = t),
                  ),
                ),
            ],
          ),
        ),
        // Datasets added to the site in the last 30 days — the same list as the
        // site's "added this month" section. Tap a chip to open it.
        ValueListenableBuilder<Set<String>>(
          valueListenable: newSlugsNotifier,
          builder: (context, fresh, _) {
            final items = [
              for (final e in catalog)
                if (fresh.contains(e.slug)) e
            ];
            if (items.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADDED THIS MONTH · ${items.length}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: kAmber),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final e in items)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(_listTitle(e),
                                  style: const TextStyle(fontSize: 12)),
                              backgroundColor: kBgCard,
                              side: BorderSide(color: kAmber, width: 0.8),
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => DatasetPage(entry: e))),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: Builder(builder: (context) {
            final featEntry = widget.featuredSlug != null
                ? catalogBySlug[widget.featuredSlug]
                : null;
            final unfiltered = _query.isEmpty && _topic == 'all';
            final showFeatured =
                featEntry != null && _featTop.isNotEmpty && unfiltered;
            // entry cards (Brands/Cities on Biz) only in the unfiltered view
            final topN = unfiltered ? widget.topCards.length : 0;
            return RefreshIndicator(
              onRefresh: () => Future.wait([loadCatalog(), _loadFeatured(), if (widget.featuredStyle == 'records') _loadRecords()]),
              color: kAmber,
              backgroundColor: kBgCard,
              // The dataset deck runs two or three abreast on a tablet. Rows
              // are still built lazily — each list item is one row of cards,
              // not the whole grid.
              child: LayoutBuilder(builder: (context, box) {
              final cols = columnsFor(box.maxWidth);
              final rows = (shown.length + cols - 1) ~/ cols;
              // Wide: the entry cards share one row instead of stacking as
              // full-width strips above the hero. Narrow: one per row, as before.
              final topRows = cols == 1 ? topN : (topN > 0 ? 1 : 0);
              final heads = topRows + (showFeatured ? 1 : 0);
              // A search with no match said nothing at all (QA, 15 Nov 2026).
              if (shown.isEmpty && _query.isNotEmpty) {
                return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('No indicators match "$_query" here — try the search at the top for every tab.',
                        textAlign: TextAlign.center, style: TextStyle(color: kTextDim)),
                  ),
                ]);
              }
              return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              itemCount: rows + heads,
              itemBuilder: (_, idx) {
                if (idx < topRows) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    child: cols == 1
                        ? widget.topCards[idx]
                        // stretch alone asks for infinite height inside a
                        // scroll view; IntrinsicHeight measures the tallest
                        // card first so both end up level.
                        : IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var j = 0; j < topN; j++) ...[
                                  if (j > 0) const SizedBox(width: 10),
                                  Expanded(child: widget.topCards[j]),
                                ],
                              ],
                            ),
                          ),
                  );
                }
                if (showFeatured && idx == topRows) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: FadeIn(child: _buildHero(featEntry)),
                  );
                }
                final start = (idx - heads) * cols;
                Widget card(CatalogEntry e) => Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  dense: true,
                  title: Text(_listTitle(e),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${e.source} · ${topicLabels[e.topic] ?? e.topic}',
                    style: TextStyle(fontSize: 12, color: kTextDim),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (newSlugsNotifier.value.contains(e.slug))
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: kAmber,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text('NEW',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: kBg)),
                        ),
                      FreshnessBadge(
                          parsedAt: e.parsedAt, latest: e.latest, compact: true),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: kTextDim, size: 20),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => DatasetPage(entry: e))),
                ),
              );
                if (cols == 1) return card(shown[start]);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var j = 0; j < cols; j++) ...[
                      if (j > 0) const SizedBox(width: 10),
                      Expanded(
                          child: start + j < shown.length
                              ? card(shown[start + j])
                              : const SizedBox.shrink()),
                    ],
                  ],
                );
              },
              );
              }),
            );
          }),
        ),
      ],
    );
  }
}

class DatasetPage extends StatefulWidget {
  final CatalogEntry entry;
  const DatasetPage({super.key, required this.entry});

  @override
  State<DatasetPage> createState() => _DatasetPageState();
}

class _DatasetPageState extends State<DatasetPage> with UsageScreen<DatasetPage> {
  @override
  String get usageScreenName => 'dataset';

  Dataset? _ds;
  Object? _error;
  String? _period;
  bool _mapView = false;
  bool _showAll = false;
  bool _asc = false; // bar order: false = highest first, true = lowest first

  @override
  void initState() {
    super.initState();
    usageDataset(widget.entry.slug);
    _load();
  }

  Future<void> _load() async {
    if (_error != null) setState(() => _error = null);
    try {
      final ds = await fetchDataset(widget.entry.slug);
      setState(() {
        _ds = ds;
        _period = _defaultPeriod(ds);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Download CSV',
            onPressed: _ds == null
                ? null
                : () => CsvExport.dataset(
                    context, widget.entry.slug, widget.entry.title, ds: _ds),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Share as image',
            onPressed: _ds == null ? null : _share,
          ),
          // Star — pin this indicator to the Favorites block on Home.
          ValueListenableBuilder(
            valueListenable: favoritesNotifier,
            builder: (_, favs, _) {
              final fav = favs.datasets.contains(widget.entry.slug);
              return IconButton(
                icon: Icon(fav ? Icons.star : Icons.star_border,
                    color: fav ? kAmber : null),
                tooltip: fav ? 'Remove from favorites' : 'Add to favorites',
                onPressed: () => toggleFavDataset(widget.entry.slug),
              );
            },
          ),
        ],
      ),
      body: _error != null
          ? LoadError(error: _error!, what: 'this indicator', onRetry: _load)
          : _ds == null
              ? _buildSkeleton()
              : _buildBody(),
    );
  }

  /// Opens the share-preview screen with a branded card of the current
  /// ranking (top of the latest period).
  void _share() {
    final ds = _ds;
    if (ds == null) return;
    // The card shows what the screen shows: same year view, same sort order.
    final rows = _rowsFor(ds, _period)
      ..sort((a, b) => _asc ? a.value.compareTo(b.value) : b.value.compareTo(a.value));
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SharePreviewPage(
        tag: ds.source,
        title: ds.title,
        bars: [
          for (final o in rows.take(6))
            ('${flagFromIso(o.iso)} ${o.entity}', o.value)
        ],
        footer: '${_period == kLatestView ? 'latest reading per country' : _period} · ${ds.unit}',
        all: [for (final o in rows) o.value],
        unit: ds.unit,
      ),
    ));
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Skeleton(width: double.infinity, height: 12),
        const SizedBox(height: 8),
        const Skeleton(width: 180, height: 10),
        const SizedBox(height: 20),
        for (var i = 0; i < 12; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Skeleton(width: 90, height: 12),
                const SizedBox(width: 8),
                Expanded(
                    child: Skeleton(
                        width: double.infinity, height: 10 + (i % 5) * 2)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    final ds = _ds!;
    final rows = _rowsFor(ds, _period)
      ..sort((a, b) =>
          _asc ? a.value.compareTo(b.value) : b.value.compareTo(a.value));
    final shown = _showAll ? rows : rows.take(20).toList();
    final ranges = _rankRanges(rows);
    final maxV = rows.isEmpty
        ? 1.0
        : rows.map((o) => o.value.abs()).reduce((a, b) => a > b ? a : b);

    return RefreshIndicator(
      onRefresh: _load,
      color: kAmber,
      backgroundColor: kBgCard,
      child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text(ds.summary,
            style: TextStyle(fontSize: 13, color: kTextDim, height: 1.4)),
        const SizedBox(height: 6),
        Text('${ds.source} · ${ds.license} · ${ds.unit}',
            style: TextStyle(fontSize: 11, color: kTextDim)),
        if (widget.entry.parsedAt.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FreshnessBadge(
                parsedAt: widget.entry.parsedAt, latest: widget.entry.latest),
          ),
        ],
        const SizedBox(height: 12),
        // One scrolling row, opened at the newest year: 35 years as a wrapped
        // grid of chips filled the first screen (owner, 15 Nov 2026).
        _YearStrip(
          periods: ds.periods,
          selected: _period,
          projectedFrom: ds.projectedFrom,
          latestOption: ds.latestPerCountry,
          onSelected: (p) => setState(() => _period = p),
        ),
        const SizedBox(height: 12),
        // Bars / Map view toggle.
        Row(
          children: [
            _ViewToggle(
                icon: Icons.bar_chart,
                label: 'Bars',
                selected: !_mapView,
                onTap: () => setState(() => _mapView = false)),
            const SizedBox(width: 8),
            _ViewToggle(
                icon: Icons.public,
                label: 'Map',
                selected: _mapView,
                onTap: () => setState(() => _mapView = true)),
            const Spacer(),
            // Sort direction — long lists don't fit, so let the user flip to
            // the bottom of the ranking without scrolling.
            if (!_mapView)
              _ViewToggle(
                  icon: _asc ? Icons.arrow_upward : Icons.arrow_downward,
                  label: _asc ? 'Lowest' : 'Highest',
                  selected: false,
                  onTap: () => setState(() => _asc = !_asc)),
          ],
        ),
        const SizedBox(height: 12),
        if (_mapView) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Choropleth(
              values: {
                for (final o in rows)
                  if (o.iso.isNotEmpty) o.iso: o.value
              },
              onTap: (iso, name) {
                final match = rows.where((o) => o.iso == iso);
                if (match.isNotEmpty) _showTrend(match.first);
              },
            ),
          ),
          const SizedBox(height: 8),
          ChoroLegend(
              low: 'Low',
              high: 'High',
              values: [for (final o in rows) if (o.iso.isNotEmpty) o.value],
              unit: ds.unit),
          const SizedBox(height: 6),
          SampleStats(values: [for (final o in rows) o.value], unit: ds.unit),
          const SizedBox(height: 6),
          Text('Tap a country for its trend · $_period · ${ds.unit}',
              style: TextStyle(fontSize: 11, color: kTextDim)),
        ] else ...[
          if (rows.length >= 3) SampleStats(values: [for (final o in rows) o.value], unit: ds.unit),
          // Surveys and estimates with a published margin: a single place
          // overstates what a sample can tell apart (statistical review,
          // 15 Nov 2026: 36 of 37 neighbouring Afrobarometer pairs overlap).
          if (ranges != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                  'Ranks are shown as ranges: where two countries\' ${ds.ciLabel.isEmpty ? 'margins of error' : 'uncertainty intervals'} overlap, '
                  'the data cannot tell which is higher.',
                  style: TextStyle(fontSize: 11.5, color: kTextDim, height: 1.35)),
            ),
          for (var i = 0; i < shown.length; i++) ...[
            // Where the median falls in the ranking, so a row reads against it.
            if (rows.length >= 3 && i == _medianSlot(shown, rows))
              _MedianRule(value: _median([for (final o in rows) o.value]), unit: ds.unit),
            _BarRow(
              // Equal values share a rank (1 + countries strictly higher), as on
              // country profiles; sort order used to spread a tie over 62 places.
              rank: 1 + rows.where((o) => o.value > shown[i].value).length,
              rankRange: ranges?[shown[i]],
              obs: shown[i],
              fraction: maxV == 0 ? 0 : (shown[i].value.abs() / maxV),
              negative: shown[i].value < 0,
              // A tick at the median inside every bar track: in the top 20 the
              // median row itself is usually out of sight (#93 of 185 on adult
              // mortality), and the owner looked for it there (15 Nov 2026).
              median: rows.length >= 3 && maxV > 0 && _median([for (final o in rows) o.value]) >= 0
                  ? _median([for (final o in rows) o.value]) / maxV
                  : null,
              onTap: () => _showTrend(shown[i]),
            ),
          ],
          // The median falls below the rows shown: say where, so the line is
          // not simply missing from a collapsed list.
          if (rows.length >= 3 && shown.isNotEmpty && _medianSlot(shown, rows) == -1 && shown.length < rows.length)
            _MedianRule(
                value: _median([for (final o in rows) o.value]),
                unit: ds.unit,
                note: 'past the ${shown.length} shown, around #${(rows.length + 1) ~/ 2}'),
          if (!_showAll && rows.length > 20)
            TextButton(
              onPressed: () => setState(() => _showAll = true),
              child: Text('Show all ${rows.length}',
                  style: TextStyle(color: kAmber)),
            ),
        ],
        chartWatermark,
      ],
      ),
    );
  }

  void _showTrend(Observation obs) {
    final ds = _ds!;
    final series = ds.data.where((o) => o.entity == obs.entity).toList()
      ..sort((a, b) => a.period.compareTo(b.period));
    // Where this reading stands in its own year — a single reading opened to
    // a lone number with no year, rank or median (testers, 15 Nov 2026).
    final peers = [for (final o in ds.data) if (o.period == obs.period && o.iso.isNotEmpty) o.value];
    final higher = peers.where((v) => v > obs.value).length;
    final tied = peers.where((v) => v == obs.value).length;
    final med = ds.medianIn(obs.period);
    final u = ds.unit.contains('%') ? '%' : '';
    final context0 = [
      obs.period,
      if (peers.length >= 3)
        // The same range the list shows, where readings carry intervals.
        (() {
          final rr = _rankRanges([for (final o in ds.data) if (o.period == obs.period && o.iso.isNotEmpty) o]);
          final r = rr?.entries.where((e) => identical(e.key, obs) || (e.key.iso == obs.iso)).firstOrNull?.value;
          final place = r != null && r.$1 != r.$2 ? '#${r.$1}–${r.$2}' : '#${higher + 1}';
          return '$place of ${peers.length}${tied > 1 ? ' (tied with ${tied - 1} other${tied > 2 ? 's' : ''})' : ''}';
        })(),
      if (med != null && peers.length >= 3)
        'median ${formatValue(med.value)}$u — ${obs.value > med.value ? 'above' : obs.value < med.value ? 'below' : 'at'} it'
            // With a published interval, say whether the gap is more than noise.
            '${obs.interval != null && (med.value >= obs.interval!.$1 && med.value <= obs.interval!.$2) ? ', within the uncertainty' : ''}',
      if (obs.interval != null)
        '${ds.ciLabel.isEmpty ? 'interval' : ds.ciLabel} ${formatValue(obs.interval!.$1)}–${formatValue(obs.interval!.$2)}$u',
    ].join(' · ');
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: kBgElev,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      // A fixed-height sheet clipped its last rows the moment the window was
      // shorter than a phone — which is exactly what App Review saw on an iPad
      // in the sibling app. Scroll instead of hiding, and don't span a 13" slab.
      isScrollControlled: true,
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9, maxWidth: 700),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(obs.entity,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('${ds.title} · ${ds.unit}',
                style: TextStyle(fontSize: 12, color: kTextDim)),
            const SizedBox(height: 4),
            Text(context0, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kText)),
            const SizedBox(height: 16),
            TrendChart(
              points: [for (final o in series) (o.period, o.value)],
              highlightPeriod: obs.period,
              unit: ds.unit,
              mode: ds.changeMode.isEmpty ? null : ds.changeMode,
              margins: [for (final o in series) o.moe],
              intervals: [for (final o in series) o.interval],
              bandLabel: ds.ciLabel.isEmpty ? null : ds.ciLabel,
              projectedFrom: ds.projectedFrom,
              // The median of the year being looked at, not of the series' last
              // year (for IMF that was the forecast year).
              reference: series.length >= 2 ? med?.value : null,
              referenceLabel: 'Median ${obs.period}, ${med?.n ?? 0} countries',
            ),
            const SizedBox(height: 4),
            chartWatermark,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Bounds of a reading: the source's interval, else value ± margin of error.
(double, double)? _bounds(Observation o) =>
    o.interval ?? (o.moe == null ? null : (o.value - o.moe!, o.value + o.moe!));

/// Rank ranges for a ranking whose readings carry bounds: a country can sit no
/// higher than 1 + the countries whose whole interval lies above its own, and
/// no lower than 1 + the countries whose interval reaches above its lower end.
/// Null when fewer than half the rows have bounds.
Map<Observation, (int, int)>? _rankRanges(List<Observation> rows) {
  final b = {for (final o in rows) o: _bounds(o)};
  if (rows.length < 3 || b.values.where((x) => x != null).length * 2 < rows.length) return null;
  final out = <Observation, (int, int)>{};
  for (final o in rows) {
    final mine = b[o] ?? (o.value, o.value);
    var surelyAbove = 0, maybeAbove = 0;
    for (final q in rows) {
      if (identical(q, o)) continue;
      final other = b[q] ?? (q.value, q.value);
      if (other.$1 > mine.$2) surelyAbove++;
      if (other.$2 > mine.$1) maybeAbove++;
    }
    out[o] = (1 + surelyAbove, 1 + maybeAbove);
  }
  return out;
}

class _BarRow extends StatelessWidget {
  final int rank;
  final (int, int)? rankRange;
  final Observation obs;
  final double fraction;
  final bool negative;
  final double? median;
  final VoidCallback onTap;
  const _BarRow(
      {required this.rank,
      this.rankRange,
      required this.obs,
      required this.fraction,
      required this.negative,
      this.median,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
                width: rankRange == null ? 26 : 46,
                child: Text(
                    rankRange == null || rankRange!.$1 == rankRange!.$2
                        ? '$rank'
                        : '${rankRange!.$1}–${rankRange!.$2}',
                    style: TextStyle(fontSize: 11, color: kTextDim))),
            SizedBox(
              width: 110,
              child: Text(obs.entity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Expanded(
                child:
                    _Bar(fraction: fraction, color: negative ? kDown : kAmber, mark: median)),
            const SizedBox(width: 8),
            SizedBox(
                width: 58,
                child: Text(formatValue(obs.value),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double fraction;
  final Color color;
  final double? mark;
  const _Bar({required this.fraction, required this.color, this.mark});

  @override
  Widget build(BuildContext context) {
    final track = Container(
      height: 10,
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fraction.clamp(0.02, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
    final m = mark;
    if (m == null || m.isNaN) return track;
    // Rows sit 6 px apart, so 18 px ticks join into one dotted median line.
    return SizedBox(
      height: 18,
      child: LayoutBuilder(builder: (context, c) {
        final x = (m.clamp(0.0, 1.0) * c.maxWidth - 1).clamp(0.0, c.maxWidth - 2);
        return Stack(alignment: Alignment.centerLeft, children: [
          track,
          Positioned(
            left: x,
            top: 0,
            bottom: 0,
            child: Container(width: 2, color: kText.withValues(alpha: 0.55)),
          ),
        ]);
      }),
    );
  }
}

/// First→last period with the net change, colour-coded up/down.
class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ViewToggle(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? kAmber : kBgCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? kAmber : kBorder, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? kOnAmber : kTextDim),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? kOnAmber : kText)),
          ],
        ),
      ),
    );
  }
}

/// A list row's title without the survey name in brackets when the subtitle
/// already names that source: "Broadband Internet at Home (AmericasBarometer)"
/// broke mid-word on a small phone ("(AmericasBaromet / er)"). The source moves
/// to the front of the subtitle, so same-named series stay apart.
String _listTitle(CatalogEntry e) {
  final m = RegExp(r'^(.*\S)\s+\(([^()]+)\)$').firstMatch(e.title);
  if (m == null) return e.title;
  final inBrackets = m.group(2)!.toLowerCase();
  final src = e.source.toLowerCase();
  final key = inBrackets.split(RegExp(r'[\s,]+')).first;
  return key.length >= 3 && src.contains(key) ? m.group(1)! : e.title;
}

double _median(List<double> v) {
  final s = [...v]..sort();
  final n = s.length;
  return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

/// Index in [shown] before which the median line goes: the first row past the
/// median in the current sort order; -1 when it falls outside what is shown.
int _medianSlot(List<Observation> shown, List<Observation> rows) {
  final m = _median([for (final o in rows) o.value]);
  final desc = shown.length < 2 || shown.first.value >= shown.last.value;
  for (var i = 0; i < shown.length; i++) {
    if (desc ? shown[i].value < m : shown[i].value > m) return i;
  }
  return -1;
}

class _MedianRule extends StatelessWidget {
  final double value;
  final String unit;
  final String? note;
  const _MedianRule({required this.value, required this.unit, this.note});

  @override
  Widget build(BuildContext context) {
    final c = kAmber.withValues(alpha: 0.7);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Divider(color: c, thickness: 1, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('median ${formatWithUnit(value, unit)}${note == null ? '' : ' · $note'}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
        ),
        Expanded(child: Divider(color: c, thickness: 1, height: 1)),
      ]),
    );
  }
}


/// The year a ranking opens on: the newest observed year. IMF series end in
/// the IMF's projection for the current year, and a forecast ranked as a
/// result read as fact (statistical review, 15 Nov 2026).
/// The "Latest" year view: each country's newest observed reading, for
/// surveys run in different years in different countries — ranking only the
/// newest year left 4 countries for extreme poverty 2025 (review, 15 Nov 2026).
const kLatestView = 'Latest';

List<Observation> _rowsFor(Dataset ds, String? period) {
  if (period != kLatestView) return ds.data.where((o) => o.period == period).toList();
  final last = _defaultObserved(ds);
  final lastY = int.tryParse(RegExp(r'\d{4}').stringMatch(last ?? '') ?? '') ?? 0;
  final best = <String, Observation>{};
  for (final o in ds.data) {
    if (o.iso.isEmpty || last == null || o.period.compareTo(last) > 0) continue;
    final y = int.tryParse(RegExp(r'\d{4}').stringMatch(o.period) ?? '') ?? 0;
    if (lastY - y > 10) continue;
    final cur = best[o.iso];
    if (cur == null || o.period.compareTo(cur.period) > 0) best[o.iso] = o;
  }
  return best.values.toList();
}

String? _defaultPeriod(Dataset ds) {
  if (ds.periods.isEmpty) return null;
  if (ds.latestPerCountry && ds.periods.length > 1) return kLatestView;
  return _defaultObserved(ds);
}

String? _defaultObserved(Dataset ds) {
  if (ds.periods.isEmpty) return null;
  final pf = ds.projectedFrom;
  if (pf == null) return ds.periods.last;
  final observed = ds.periods
      .where((p) => (double.tryParse(RegExp(r'\d{4}').stringMatch(p) ?? '') ?? 0) < pf)
      .toList();
  return observed.isEmpty ? ds.periods.last : observed.last;
}

/// Years as one horizontal row of chips, newest at the right and in view.
class _YearStrip extends StatelessWidget {
  final List<String> periods;
  final String? selected;
  final double? projectedFrom;
  final ValueChanged<String> onSelected;
  final bool latestOption;
  const _YearStrip(
      {required this.periods,
      required this.selected,
      required this.projectedFrom,
      required this.onSelected,
      this.latestOption = false});

  bool _projected(String p) {
    final pf = projectedFrom;
    if (pf == null) return false;
    final y = double.tryParse(RegExp(r'\d{4}').stringMatch(p) ?? '');
    return y != null && y >= pf;
  }

  @override
  Widget build(BuildContext context) {
    if (periods.length < 2) {
      return periods.isEmpty
          ? const SizedBox.shrink()
          : Text(periods.first, style: TextStyle(fontSize: 12, color: kTextDim));
    }
    final newestFirst = [if (latestOption) kLatestView, ...periods.reversed];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Reversed so the newest year starts in view at the right edge.
        reverse: true,
        itemCount: newestFirst.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final p = newestFirst[i];
          final on = p == selected;
          return ChoiceChip(
            label: Text(_projected(p) ? '$p est.' : p, style: const TextStyle(fontSize: 12)),
            selected: on,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            labelStyle: TextStyle(fontWeight: FontWeight.w600, color: on ? kOnAmber : kText),
            onSelected: (_) => onSelected(p),
          );
        },
      ),
    );
  }
}
