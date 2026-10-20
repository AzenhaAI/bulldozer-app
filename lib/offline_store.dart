import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'catalog_store.dart';

/// Everything the app reads, fetched in one go into the same file cache that
/// [fetchJson] already falls back to when offline.
///
/// A tester asked whether the data could be downloaded and used offline, "as
/// an archive". The cache already kept every page opened once; what was
/// missing was a way to fill it in advance. No new storage, no new format:
/// after a download every page simply finds its file.
///
/// Size, measured on the site build of 11 Oct 2026: 273 datasets, 232
/// briefs and 9 index files, about 25 MB on disk (24 MB measured on the simulator). Nothing else is fetched —
/// Wikipedia summaries and coat-of-arms images stay online-only.
class OfflineStore {
  static const _kDate = 'offline.date';
  static const _kFiles = 'offline.files';

  static final dateNotifier = ValueNotifier<String?>(null);
  static final filesNotifier = ValueNotifier<int>(0);

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    dateNotifier.value = p.getString(_kDate);
    filesNotifier.value = p.getInt(_kFiles) ?? 0;
  }

  static const _indexes = [
    '/data/manifest.json',
    '/data/catalog.json',
    '/data/country-index.json',
    '/data/country-meta.json',
    '/data/stories.json',
    '/data/releases.json',
    '/data/brands.json',
    '/data/cities.json',
    '/data/quiz-pool.json',
  ];

  /// Fetches every file; [onProgress] gets (done, total). Returns the number
  /// of files that failed, so the caller can say "all" or "most".
  /// [cancelled] is read between files; a cancelled run keeps what it got.
  static Future<int> downloadAll({
    required void Function(int done, int total) onProgress,
    bool Function()? cancelled,
  }) async {
    // The catalogue and the country index decide what else to fetch, so they
    // come first and fresh.
    await loadCatalog();
    final countries = await fetchCountryIndex();
    final paths = <String>[
      ..._indexes,
      for (final e in catalog) '/data/${e.slug}.json',
      for (final c in countries) '/data/brief/${c.iso.toLowerCase()}.json',
    ];
    final total = paths.length;
    var done = 0, failed = 0;
    onProgress(0, total);
    // A few at a time: fast enough on Wi-Fi, gentle on a phone connection.
    const lanes = 6;
    var next = 0;
    Future<void> lane() async {
      while (next < paths.length) {
        if (cancelled?.call() ?? false) return;
        final path = paths[next++];
        try {
          await fetchJson(path);
        } catch (_) {
          failed++;
        }
        done++;
        onProgress(done, total);
      }
    }
    await Future.wait([for (var i = 0; i < lanes; i++) lane()]);
    if (!(cancelled?.call() ?? false)) {
      final p = await SharedPreferences.getInstance();
      final stamp = DateTime.now().toIso8601String().substring(0, 10);
      await p.setString(_kDate, stamp);
      await p.setInt(_kFiles, done - failed);
      dateNotifier.value = stamp;
      filesNotifier.value = done - failed;
    }
    return failed;
  }
}
