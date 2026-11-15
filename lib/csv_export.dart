import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'api.dart';
import 'theme.dart';

/// CSV export — the site already serves `/data/{slug}.csv`, so a dataset
/// download is a straight fetch + share. Country exports are built on device
/// from the country index (there is no per-country CSV endpoint).
class CsvExport {
  /// Downloads `/data/{slug}.csv` and opens the system share sheet. The file
  /// starts with `# …` comment lines naming the source, licence, unit and the
  /// dataset page, so a CSV passed on still says where it came from. Pass [ds]
  /// when the caller already holds the dataset; otherwise its metadata is
  /// fetched (best-effort — the CSV is shared without the header if that fails).
  static Future<void> dataset(BuildContext context, String slug, String title,
      {Dataset? ds}) async {
    _toast(context, 'Preparing $title.csv…');
    try {
      final meta = ds != null
          ? Future<Dataset?>.value(ds)
          : fetchDataset(slug)
              .timeout(_timeout)
              .then<Dataset?>((d) => d, onError: (_) => null);
      final http.Response res;
      try {
        res = await http
            .get(Uri.parse('$kBaseUrl/data/$slug.csv'))
            .timeout(_timeout);
      } on TimeoutException {
        throw const _ExportError(
            'Couldn\'t download the data — the connection timed out.');
      } on Exception {
        throw const _ExportError(
            'Couldn\'t download the data — check the connection.');
      }
      if (res.statusCode == 404) {
        throw const _ExportError(
            'This dataset has no CSV download yet.');
      }
      if (res.statusCode != 200) {
        throw _ExportError(
            'Couldn\'t download the data — the server answered ${res.statusCode}. Try again later.');
      }
      final header = csvHeader(slug, title, await meta);
      var body = res.bodyBytes.toList();
      // A UTF-8 byte-order mark belongs at the very start of the file.
      final bom = body.length >= 3 &&
          body[0] == 0xEF && body[1] == 0xBB && body[2] == 0xBF;
      if (bom) body = body.sublist(3);
      final bytes = <int>[
        if (bom) ...[0xEF, 0xBB, 0xBF],
        ...utf8.encode(header),
        ...body
      ];
      if (!context.mounted) return;
      await _shareBytes(context, bytes, '$slug.csv',
          '$title — BullDozer Stats · azenha.ai/bulldozer');
    } on _ExportError catch (e) {
      if (context.mounted) _toast(context, e.message);
    } catch (_) {
      if (context.mounted) {
        _toast(context, 'Couldn\'t export the CSV. Please try again.');
      }
    }
  }

  static const _timeout = Duration(seconds: 20);

  /// The `# …` lines put before the site's CSV: title, source, licence, unit
  /// and where the dataset lives.
  @visibleForTesting
  static String csvHeader(String slug, String title, Dataset? ds) {
    String clean(String v) => v.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
    final lines = <String>[
      '# ${clean(ds?.title.isNotEmpty == true ? ds!.title : title)}',
      if (ds != null && ds.source.isNotEmpty) '# Source: ${clean(ds.source)}',
      if (ds != null && ds.license.isNotEmpty)
        '# Licence: ${clean(ds.license)}',
      if (ds != null && ds.unit.isNotEmpty) '# Unit: ${clean(ds.unit)}',
      '# Dataset: $kSiteUrl/dataset/$slug/',
      if (ds != null && ds.url.isNotEmpty)
        '# Publisher page: ${clean(ds.url)}',
      '# Exported from BullDozer Stats · azenha.ai/bulldozer',
    ];
    return '${lines.join('\n')}\n';
  }

  /// Builds a CSV of every indicator for one country (mirrors the site's
  /// "Download country CSV" button on the country panel).
  static Future<void> country(BuildContext context, Country c) async {
    _toast(context, 'Preparing ${c.name}.csv…');
    try {
      String esc(Object? v) => '"${'$v'.replaceAll('"', '""')}"';
      final rows = <String>[
        'indicator,kind,topic,value,unit,period,rank,total',
        for (final it in [...c.items]..sort((a, b) => a.kind == b.kind
            ? a.title.compareTo(b.title)
            : (a.kind == 'macro' ? -1 : 1)))
          [
            esc(it.title),
            it.kind,
            it.topic,
            it.value,
            esc(it.unit),
            it.period,
            it.rank,
            it.total
          ].join(','),
      ];
      final name = '${c.name.replaceAll(RegExp(r'[^\w]+'), '_')}_bulldozer.csv';
      await _shareBytes(
          context,
          utf8.encode(rows.join('\n')),
          name,
          '${c.name} — ${c.items.length} indicators · azenha.ai/bulldozer');
    } catch (e) {
      if (context.mounted) {
        _toast(context, 'Couldn\'t export the CSV. Please try again.');
      }
    }
  }

  static Future<void> _shareBytes(BuildContext context, List<int> bytes,
      String filename, String text) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$filename');
    await f.writeAsBytes(bytes);
    await SharePlus.instance
        .share(ShareParams(files: [XFile(f.path)], text: text));
  }

  static void _toast(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: kBgCard,
      duration: const Duration(seconds: 2),
      content: Text(msg, style: TextStyle(color: kText, fontSize: 12)),
    ));
  }
}

class _ExportError implements Exception {
  final String message;
  const _ExportError(this.message);
}
