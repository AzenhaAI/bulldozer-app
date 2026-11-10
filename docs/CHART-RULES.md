# Chart rules for time series (app + site)

Agreed 10 Nov 2026 after a TestFlight review was requested. The same logic
runs on the website (`bulldozer/src/lib/trend.ts`) and in the app
(`lib/widgets/chart_rules.dart`); both are checked against SciPy and
pymannkendall on 86 series (`test/trend_vectors.json`).

Owner's decision (10 Nov): keep **3–6 and the trend line**; drop 1–2 (no
"number instead of a flat chart", no zero floor / minimum span): the axis
zooms to the data so every change is visible.

| Rule | What the chart does |
|------|---------------------|
| Reference (3) | Dotted "Median, N countries: X" line when it falls inside the range; otherwise the same text under the chart (a far-off median would flatten the line) |
| Caption (4) | "−1.6 pp since 2013"; % for money/people; growth rates: compound average ("compound average +2.0% per year, 2019–2025") |
| Uncertainty (5) | Survey series: band = 95% margin of error (Kish effective n; the site's `scripts/tools/moe.py`), in `moe` on each observation. IMF: years ≥ `projectedFrom` on a shaded "IMF forecast" stretch, out of the trend |
| Smoothing (6) | ≥ 20 readings: LOWESS curve (statsmodels-identical) over a faint yearly line |
| Trend | Dashed Theil–Sen line over observed years when ≥ 6 readings, Mann–Kendall p < 0.05 and the same direction in both halves; money/people fitted on logs (rate in % per year) |
| Also | x by year (waves at their midpoint); straight segments (a curve invented values); round ticks with a 0 line; a key line under the chart |

The home "trend" card now shows the median of the same countries in every
period ("median of 16 countries"), not an average over whoever reported.

## What is in the branch `chart-rules`

- `lib/widgets/chart_rules.dart` — new, pure Dart (no Flutter import).
- `lib/widgets/trend_chart.dart` — rewritten; the old call
  `TrendChart(points:, highlightPeriod:, height:)` still works, new optional
  parameters: `unit`, `mode`, `margins`, `projectedFrom`, `reference`,
  `referenceLabel`, `showTrend`, `showCaption`.
- `lib/api.dart` — `Observation.moe`; `Dataset` gains `changeMode`,
  `projectedFrom`, `latestPerCountry`, `panelMedians()`, `medianIn(period)`.
- `lib/charts_page.dart`, `lib/countries_page.dart` — call sites pass the new
  parameters; the old `_TrendSummary` row is gone (the chart caption replaces it).
- Tests: `test/trend_chart_test.dart` (9 widget tests),
  `tools/check_chart_rules.dart` (86 trend cases vs SciPy/pymannkendall,
  31 LOWESS series vs statsmodels, 6 rule checks; plain `dart run`),
  `test/render_charts_test.dart` (renders real series to PNG; skipped unless
  `RENDER_FIXTURES` is set).

**This branch is cut from GitHub `main` (1.28.0+44); the Mac has 1.38.x.**
Port it onto the Mac's code rather than merging blindly:
1. Copy `chart_rules.dart` and `trend_chart.dart` as they are.
2. Add the `Dataset` fields and helpers from `api.dart`.
3. At every `TrendChart(` call (`grep -rn "TrendChart(" lib`), pass `unit`,
   `mode`, `margins: [for (o in series) o.moe]`, `projectedFrom` and, on
   per-country sheets, `reference: ds.medianIn(lastPeriod)?.value` with
   `referenceLabel: 'Median, ${…n} countries'`; the home trend card uses
   `ds.panelMedians()`. Remove any separate
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

Screens to look at in TestFlight:
- Ghana → Support for Democracy: margin band, waves at their midpoints, "no steady trend" (rise then fall)
- Georgia → Climate Seen as a Threat (World Risk Poll): margin band
- Germany → Renewable Electricity: dashed trend +3.6 pp per year
- Iceland → Life Expectancy: smoothed curve over 35 years
- China → GDP per Capita (Long Run): log trend, +3.1% per year
- Russia → Real GDP Growth: shaded 2026 IMF forecast, compound average caption
- USA → Government Debt: forecast shading, median noted under the chart
- Burundi → Extreme Poverty: two surveys; the 2.35% median is below the range, so it is written, not drawn
- Home trend card: "median of N countries"
