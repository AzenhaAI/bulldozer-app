import 'package:bulldozer_app/widgets/trend_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget w) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SizedBox(width: 380, child: w))));
LineChartData chart(WidgetTester t) => t.widget<LineChart>(find.byType(LineChart)).data;

void main() {
  testWidgets('flat series is still a chart (owner: changes must be visible)', (t) async {
    await t.pumpWidget(host(TrendChart(points: [for (var y = 2016; y <= 2023; y++) ('$y', 0.0)], unit: '%')));
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('axis zooms to the data', (t) async {
    await t.pumpWidget(host(const TrendChart(points: [('2013', 75.8), ('2020', 74.2)], unit: '%')));
    final d = chart(t);
    expect(d.minY, greaterThan(70));
    expect(d.maxY, lessThan(80));
  });

  testWidgets('x is placed by year, straight segments', (t) async {
    await t.pumpWidget(host(const TrendChart(points: [('2013', 75.8), ('2020', 74.2)], unit: '%')));
    final main = chart(t).lineBarsData.first;
    expect(main.spots.map((s) => s.x).toList(), [2013, 2020]);
    expect(main.isCurved, isFalse);
  });

  testWidgets('steady rise: dashed trend and caption', (t) async {
    await t.pumpWidget(host(TrendChart(points: [for (var y = 2016; y <= 2023; y++) ('$y', 50.0 + (y - 2016) * 1.5)], unit: '%')));
    expect(chart(t).lineBarsData.where((b) => b.dashArray != null).length, 1);
    expect(find.textContaining('trend +1.5 pp per year'), findsOneWidget);
    expect(find.textContaining('+10.5 pp since 2016'), findsOneWidget);
  });

  testWidgets('rise then fall: no trend line', (t) async {
    await t.pumpWidget(host(TrendChart(
        points: [for (var i = 0; i < 8; i++) ('${2016 + i}', [70, 74, 77, 78, 77, 74, 70, 66][i].toDouble())], unit: '%')));
    expect(chart(t).lineBarsData.where((b) => b.dashArray != null), isEmpty);
    expect(find.textContaining('no steady trend'), findsOneWidget);
  });

  testWidgets('projections shaded and out of the fit; compound growth caption', (t) async {
    await t.pumpWidget(host(const TrendChart(
        points: [('2019', 2.0), ('2020', -3.0), ('2021', 5.0), ('2022', 3.0), ('2023', 2.5), ('2024', 2.4), ('2025', 2.6), ('2026', 2.8)],
        unit: '% YoY', projectedFrom: 2026)));
    final d = chart(t);
    expect(d.rangeAnnotations.verticalRangeAnnotations.length, 1);
    expect(d.rangeAnnotations.verticalRangeAnnotations.first.x1, 2025.5);
    expect(find.textContaining('compound average +2.0% per year, 2019–2025'), findsOneWidget);
    expect(d.minY, lessThan(-3));
  });

  testWidgets('survey margins: a band between two edges', (t) async {
    await t.pumpWidget(host(const TrendChart(
        points: [('2002–2004', 71.0), ('2021–2023', 68.0), ('2024–2025', 66.3)], margins: [2.5, 2.1, 2.0], unit: '%')));
    final d = chart(t);
    expect(d.betweenBarsData.length, 1);
    expect(d.lineBarsData[2].spots.map((s) => s.x).toList(), [2003, 2022, 2024.5]);
    expect(find.textContaining('margin of error'), findsOneWidget);
  });

  testWidgets('long series: LOWESS curve over a faint line', (t) async {
    await t.pumpWidget(host(TrendChart(points: [for (var y = 1990; y < 2025; y++) ('$y', 70 + (y - 1990) * 0.2 + (y.isEven ? 0.4 : -0.4))], unit: 'years')));
    final d = chart(t);
    expect(d.lineBarsData.where((b) => b.barWidth == 2.8).length, 1);
    expect(find.textContaining('thick: smoothed'), findsOneWidget);
  });

  testWidgets('far-off median goes to the caption, not the axis', (t) async {
    await t.pumpWidget(host(const TrendChart(points: [('2013', 75.8), ('2020', 74.2)], unit: '%', reference: 2.35, referenceLabel: 'Median, 164 countries')));
    expect(chart(t).extraLinesData.horizontalLines, isEmpty);
    expect(find.textContaining('Median, 164 countries: 2.35%'), findsOneWidget);
  });
}
