// Renders TrendChart for real series to PNGs for a visual check:
//   RENDER_FIXTURES=fixtures.json RENDER_OUT=dir flutter test test/render_charts_test.dart
// Skipped when RENDER_FIXTURES is not set (so the normal suite stays fast).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bulldozer_app/theme.dart';
import 'package:bulldozer_app/widgets/trend_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadInter() async {
  final loader = FontLoader('Inter');
  for (final w in ['regular', '500', '600', '800']) {
    final b = File('assets/fonts/inter-v20-latin-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(b.buffer)));
  }
  await loader.load();
}

void main() {
  final fx = Platform.environment['RENDER_FIXTURES'];
  final out = Platform.environment['RENDER_OUT'] ?? 'build/render';
  testWidgets('render', (t) async {
    await t.runAsync(loadInter);
    t.view.physicalSize = const Size(390 * 2, 380 * 2);
    t.view.devicePixelRatio = 2;
    final cases = (jsonDecode(File(fx!).readAsStringSync()) as List).cast<Map>();
    Directory(out).createSync(recursive: true);
    for (final c in cases) {
      final key = GlobalKey();
      final ref = (c['ref'] as num?)?.toDouble();
      await t.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'Inter', brightness: Brightness.dark),
        home: Scaffold(
          backgroundColor: kBgElev,
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: kBgElev,
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${c['title']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('${c['name']} · ${c['unit']}', style: TextStyle(fontSize: 12, color: kTextDim)),
                const SizedBox(height: 16),
                TrendChart(
                  points: [for (final p in c['points'] as List) ('${p[0]}', (p[1] as num).toDouble())],
                  highlightPeriod: '${(c['points'] as List).last[0]}',
                  unit: '${c['unit']}',
                  mode: '${c['mode']}'.isEmpty ? null : '${c['mode']}',
                  margins: c['margins'] == null ? null : [for (final m in c['margins'] as List) (m as num?)?.toDouble()],
                  projectedFrom: c['projectedFrom'] == null ? null : double.parse('${c['projectedFrom']}'),
                  reference: ref,
                  referenceLabel: 'Median, ${c['refN'] ?? '?'} countries',
                ),
              ]),
            ),
          ),
        ),
      ));
      await t.pumpAndSettle();
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await t.runAsync(() async {
        final img = await boundary.toImage(pixelRatio: 2);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$out/${c['name']}.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
  }, skip: fx == null);
}
