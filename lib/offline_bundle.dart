import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The catalogue baked into the app (assets/offline/data.json.gz, made by
/// scripts/bake_offline_data.py), so a phone with no connection — on first
/// launch, or with mobile data switched off — still opens every indicator
/// and country instead of a page of "No connection". Same idea as PapaGaio's
/// bundled dictionary.
///
/// It is not read directly. The first time a fetch fails and the cache has no
/// file for it, the bundle is unpacked once into the same cache that
/// [fetchJson] falls back to, in a background isolate (28 MB of JSON would
/// stall the UI). Files already in the cache are left alone: they are newer
/// than the bundle. Online, every fetch still goes to the network first.
class OfflineBundle {
  static Future<bool>? _seeding;

  /// The date of the baked data ("2026-10-11"), known after unpacking.
  static String? asOf;

  /// Unpacks the bundle into [cacheDir] once per run; later calls wait for the
  /// same result. Returns false when there is no bundle or it is damaged.
  static Future<bool> seed(Directory cacheDir) => _seeding ??= _seed(cacheDir);

  static Future<bool> _seed(Directory cacheDir) async {
    if (kIsWeb) return false;
    try {
      final bytes = (await rootBundle.load('assets/offline/data.json.gz')).buffer.asUint8List();
      final dir = cacheDir.path;
      asOf = await Isolate.run(() => _unpack(bytes, dir));
      return true;
    } catch (_) {
      _seeding = null; // let a later failure try again
      return false;
    }
  }
}

/// Cache file name for a data path — must match api.dart's _cacheFile.
String cacheNameFor(String path) => 'bd_${path.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}';

String _unpack(Uint8List gz, String dir) {
  final j = jsonDecode(utf8.decode(gzip.decode(gz))) as Map<String, dynamic>;
  final files = j['files'] as Map<String, dynamic>;
  for (final e in files.entries) {
    final f = File('$dir/${cacheNameFor(e.key)}');
    if (!f.existsSync()) f.writeAsStringSync(e.value as String);
  }
  return '${j['asOf'] ?? ''}';
}
