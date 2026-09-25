import 'package:flutter/foundation.dart';

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

/// Datasets added to the site in the last 30 days, by the site's own date.
///
/// One definition on both surfaces: the site's "added this month" section and
/// this strip both read firstSeen, the date a dataset first appeared, never
/// parsedAt, which is only the last re-parse. It used to be "new since this
/// device last looked", which showed nothing on a first launch — exactly when
/// a newcomer would want it — and differed from what the site said.
final newSlugsNotifier = ValueNotifier<Set<String>>(_recent(bakedCatalog));

Set<String> _recent(List<CatalogEntry> list) {
  final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 30));
  return {
    for (final e in list)
      if (e.firstSeen.isNotEmpty && (DateTime.tryParse(e.firstSeen)?.isAfter(cutoff) ?? false)) e.slug
  };
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
            e['firstSeen'] ?? '',
          ),
      ];
      newSlugsNotifier.value = _recent(catalogNotifier.value);
    }
  } catch (_) {
    // offline or endpoint missing — keep the baked/cached catalog
  }
}
