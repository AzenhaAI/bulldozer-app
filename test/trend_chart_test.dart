import 'package:bulldozer_app/widgets/trend_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget w) => MaterialApp(home: Scaffold(body: SizedBox(width: 380, child: w)));

void main() {
  testWidgets('flat zero series: a number, not a chart with a −1…1 axis', (t) async {
    await t.pumpWidget(host(TrendChart(points: [for (var y = 2016; y <= 2023; y++) ('$y', 0.0)], unit: '%')));
    expect(find.byType(LineChart), findsNothing);
    expect(find.text('unchanged since 2016'), findsOneWidget);
  });

  testWidgets('non-negative data never gets a negative axis', (t) async {
    await t.pumpWidget(host(TrendChart(points: const [('2018', 0.2), ('2019', 0.1), ('2020', 0.3)], unit: '%')));
    final d = t.widget<LineChart>(find.byType(LineChart)).data;
    expect(d.minY, greaterThanOrEqualTo(0));
  });

  testWidgets('x is placed by year, not by index', (t) async {
    await t.pumpWidget(host(TrendChart(points: const [('2013', 75.8), ('2020', 74.2)], unit: '%')));
    final d = t.widget<LineChart>(find.byType(LineChart)).data;
    expect(d.lineBarsData.first.spots.map((s) => s.x).toList(), [2013, 2020]);
    expect(d.lineBarsData.first.isCurved, isFalse);
  });

  testWidgets('clear rise: dashed trend line and caption', (t) async {
    await t.pumpWidget(host(TrendChart(
        points: [for (var y = 2016; y <= 2023; y++) ('$y', 50.0 + (y - 2016) * 1.5)], unit: '%')));
    final d = t.widget<LineChart>(find.byType(LineChart)).data;
    expect(d.lineBarsData.where((b) => b.dashArray != null).length, 1);
    expect(find.textContaining('trend +1.5 pp a year'), findsOneWidget);
    expect(find.textContaining('+10.5 pp since 2016'), findsOneWidget);
  });

  testWidgets('noisy series: no trend line, says so', (t) async {
    await t.pumpWidget(host(TrendChart(
        points: const [('2016', 5), ('2017', 7), ('2018', 4), ('2019', 6), ('2020', 5), ('2021', 7), ('2022', 4)], unit: '%')));
    final d = t.widget<LineChart>(find.byType(LineChart)).data;
    expect(d.lineBarsData.where((b) => b.dashArray != null), isEmpty);
    expect(find.textContaining('no clear trend'), findsOneWidget);
  });

  testWidgets('projections dashed and out of the fit', (t) async {
    await t.pumpWidget(host(TrendChart(
        points: const [('2019', 2.0), ('2020', -3.0), ('2021', 5.0), ('2022', 3.0), ('2023', 2.5), ('2024', 2.4), ('2025', 2.6), ('2026', 2.8)],
        unit: '% YoY', projectedFrom: 2026)));
    final d = t.widget<LineChart>(find.byType(LineChart)).data;
    final dashed = d.lineBarsData.where((b) => b.dashArray != null).toList();
    expect(dashed.length, 1);
    expect(dashed.first.spots.map((s) => s.x).toList(), [2025, 2026]);
    expect(d.minY, lessThan(-3)); // growth can be negative
  });

  testWidgets('survey wave labels sit at the wave midpoint', (t) async {
    await t.pumpWidget(host(TrendChart(points: const [('2002–2004', 71.0), ('2021–2023', 68.0), ('2024–2025', 66.3)], unit: '%')));
    final d = t.widget<LineChart>(find.byType(LineChart)).data;
    expect(d.lineBarsData.first.spots.map((s) => s.x).toList(), [2003, 2022, 2024.5]);
  });
}
