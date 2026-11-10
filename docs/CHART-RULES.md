# Chart rules for time series (app + site)

Agreed 10 Nov 2026 after a TestFlight review was requested. The same logic
runs on the website (`bulldozer/src/lib/trend.ts`) and in the app
(`lib/widgets/chart_rules.dart`); both are checked against SciPy and
pymannkendall on 86 series (`test/trend_vectors.json`).

| # | Rule | Why |
|---|------|-----|
| 1 | Flat series (all values equal at 1 decimal) → big number + "unchanged since 2016", no chart | A flat line on a −1…1 axis said nothing and looked broken |
| 2 | y-axis never below 0 when the dataset has no negative value; soft area fill only when the axis starts at 0; minimum span 10 % of the value | No negative poverty; tiny noise not drawn as a cliff |
| 3 | x placed by year; survey waves ("2021–2023") at their midpoint | 2013 → 2020 is seven years, not one step |
| 4 | Caption: change first → last ("−1.6 pp since 2013"; % for money/people); for growth rates the average ("average +2.0% a year, 2019–2025") | Says the change in words |
| 5 | Dashed Theil–Sen trend line over the observed years only, when ≥ 6 readings and Mann–Kendall p < 0.05; else "no clear trend" | A robust slope, and only where the direction is consistent |
| 6 | IMF projections (year ≥ `projectedFrom` in the dataset JSON, e.g. 2026) dashed and left out of the trend | Forecasts are not data |
| 7 | Straight segments (`isCurved: false`) | A curve invents values between readings |
| 8 | Dotted "Median of N" reference line (each country's latest reading for latest-per-country series) | Context: above or below the others |

Under evaluation in TestFlight (keep or roll back): 5 (trend line) and 8
(reference line). 1–4, 6, 7 are agreed.

## What is in the branch `chart-rules`

- `lib/widgets/chart_rules.dart` — new, pure Dart (no Flutter import).
- `lib/widgets/trend_chart.dart` — rewritten; the old call
  `TrendChart(points:, highlightPeriod:, height:)` still works, new optional
  parameters: `unit`, `mode`, `nonNegative`, `projectedFrom`, `reference`,
  `referenceLabel`, `showTrend`, `showCaption`.
- `lib/api.dart` — `Dataset` gains `changeMode`, `projectedFrom`,
  `latestPerCountry`, `nonNegative`, `medianIn(period)`.
- `lib/charts_page.dart`, `lib/countries_page.dart` — call sites pass the new
  parameters; the old `_TrendSummary` row is gone (the chart caption replaces it).
- Tests: `test/trend_chart_test.dart` (7 widget tests),
  `tools/check_chart_rules.dart` (91 checks vs SciPy, plain `dart run`),
  `test/render_charts_test.dart` (renders real series to PNG; skipped unless
  `RENDER_FIXTURES` is set).

**This branch is cut from GitHub `main` (1.28.0+44); the Mac has 1.38.x.**
Port it onto the Mac's code rather than merging blindly:
1. Copy `chart_rules.dart` and `trend_chart.dart` as they are.
2. Add the `Dataset` fields and helpers from `api.dart`.
3. At every `TrendChart(` call (`grep -rn "TrendChart(" lib`), pass `unit`,
   `mode`, `nonNegative`, `projectedFrom` and, on per-country sheets,
   `reference: ds.medianIn(lastPeriod)?.value` with
   `referenceLabel: 'Median of ${…n}'`. Remove any separate
   "first → last" row under the chart.
4. fl_chart: the branch uses the 0.69 API `SideTitleWidget(axisSide: meta.axisSide, …)`.
   On fl_chart ≥ 0.70 write `SideTitleWidget(meta: meta, …)`.

## Check on the Mac, then TestFlight

```bash
flutter analyze
```

```bash
flutter test test/trend_chart_test.dart
```

```bash
dart run tools/check_chart_rules.dart
```

Then bump `version:` in `pubspec.yaml`, `flutter build ipa --release`, upload
with Transporter (or Xcode Organizer), and add the build to the internal
TestFlight group.

Screens to look at in TestFlight: any country → Extreme Poverty (Burundi:
two surveys, 2013 and 2020); Renewable Electricity for Germany (clear rise,
trend line); Gibraltar renewables (flat → number); Russia GDP growth (negative
axis allowed, 2026 dashed, average caption); Ghana → Support for Democracy
(survey waves by midpoint); the home "trend" hero card.
