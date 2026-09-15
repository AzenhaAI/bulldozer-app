import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'catalog.dart';

export 'catalog.dart' show CatalogEntry;

/// The active dataset catalog. Starts from the baked offline fallback and is
/// replaced by the live `/data/catalog.json` once loaded — so new datasets
/// added on the site show up without rebuilding the app.
final catalogNotifier = ValueNotifier<List<CatalogEntry>>(bakedCatalog);

List<CatalogEntry> get catalog => catalogNotifier.value;

Map<String, CatalogEntry> get catalogBySlug =>
    {for (final e in catalog) e.slug: e};

/// Site discovery manifest — freshest parse date + resource counts. Lets the
/// app show "data updated …" and auto-know what the site offers.
class Manifest {
  final String freshestParse;
  final Map<String, int> counts;
  const Manifest(this.freshestParse, this.counts);
}

final manifestNotifier = ValueNotifier<Manifest?>(null);

Future<void> loadManifest() async {
  try {
    final data = await fetchJson('/data/manifest.json');
    if (data is Map) {
      manifestNotifier.value = Manifest(
        data['freshestParse'] ?? '',
        {
          for (final e in (data['counts'] as Map? ?? {}).entries)
            '${e.key}': (e.value is num) ? (e.value as num).toInt() : 0
        },
      );
    }
  } catch (_) {
    // manifest is best-effort — the app works without it
  }
}

/// Datasets that were not in the catalogue the last time this app ran.
///
/// "New" is measured against what this person has already seen, not against a
/// date: `parsedAt` is when a series was last refreshed, and a re-parsed GDP
/// is not news. Empty on the very first run — everything is new then, which
/// is the same as nothing being new. A tester asked where the fresh data had
/// gone; it was in five places, and nothing said so.
final newSlugsNotifier = ValueNotifier<Set<String>>({});

const _seenKey = 'catalog.seen_slugs';

Future<void> _markNew(List<CatalogEntry> fresh) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getStringList(_seenKey) ?? const []).toSet();
    final now = {for (final e in fresh) e.slug};
    if (seen.isNotEmpty) newSlugsNotifier.value = now.difference(seen);
    // Written at once, so the strip shows for this session and not the next:
    // "since your last visit" has to mean that.
    await prefs.setStringList(_seenKey, now.toList());
  } catch (_) {
    // preferences unavailable — the catalogue still works, just without the strip
  }
}

/// Loads the live catalog (cached by [fetchJson]); keeps the baked/cached list
/// on any failure.
Future<void> loadCatalog() async {
  try {
    final data = await fetchJson('/data/catalog.json');
    if (data is List && data.isNotEmpty) {
      catalogNotifier.value = [
        for (final e in data)
          CatalogEntry(
            e['slug'] ?? '',
            e['title'] ?? '',
            e['unit'] ?? '',
            e['kind'] ?? 'macro',
            e['topic'] ?? 'economy',
            e['source'] ?? '',
            e['parsedAt'] ?? '',
            e['latest'] ?? '',
          ),
      ];
      await _markNew(catalogNotifier.value);
    }
  } catch (_) {
    // offline or endpoint missing — keep the baked/cached catalog
  }
}
