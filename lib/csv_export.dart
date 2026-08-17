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
  /// Downloads `/data/{slug}.csv` and opens the system share sheet.
  static Future<void> dataset(
      BuildContext context, String slug, String title) async {
    _toast(context, 'Preparing $title.csv…');
    try {
      final res = await http.get(Uri.parse('$kBaseUrl/data/$slug.csv'));
      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';
      if (!context.mounted) return;
      await _shareBytes(context, res.bodyBytes, '$slug.csv',
          '$title — BullDozer · azenha.ai/bulldozer');
    } catch (e) {
      if (context.mounted) _toast(context, 'Couldn\'t export: $e');
    }
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
      if (context.mounted) _toast(context, 'Couldn\'t export: $e');
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
