import 'package:flutter/material.dart';

import 'theme.dart';

/// Edu → "Statistics basics": the terms and formulas behind every number the
/// app prints — median and mean, percentage points, rates, margins of error,
/// the trend test — each with a worked example. Native, so it reads offline
/// (owner, 15 Nov 2026). Examples are worked arithmetic or figures the app
/// itself shows; nothing here is a claim about a country that is not in the data.
class StatsBasicsPage extends StatelessWidget {
  const StatsBasicsPage({super.key});

  static const _sections = <(String, List<_Term>)>[
    (
      'Reading a ranking',
      [
        _Term(
          'Mean (average)',
          'Add every value and divide by how many there are. One extreme country pulls it '
              'towards itself.',
          'mean = (x₁ + x₂ + … + xₙ) ÷ n',
          'Adult mortality, 2023: mean 149 per 1,000 over 185 countries — above the median, '
              'because a few countries with very high values pull it up.',
        ),
        _Term(
          'Median',
          'Sort the values; the median is the one in the middle. Half the countries are above '
              'it, half below. Extremes do not move it, so it is the better "typical country".',
          'odd n: the ((n + 1) ÷ 2)-th value · even n: average of the two middle values',
          'Adult mortality, 2023: median 138 — the 93rd of 185 countries. In the app it is the '
              'thin vertical tick inside every bar.',
        ),
        _Term(
          'Unweighted ("each country counted once")',
          'Our medians and means treat Tuvalu and India alike: one country, one value. A '
              'population-weighted figure answers a different question — "the typical person".',
          'weighted mean = Σ(wᵢ·xᵢ) ÷ Σwᵢ, with wᵢ = population',
          'If a small country with a high value and a huge country with a low value are '
              'averaged, the unweighted mean sits halfway; the weighted one sits near the huge country.',
        ),
        _Term(
          'Rank, quartiles and percentiles',
          'Rank #1 is the highest value, whatever the indicator measures — on mortality #1 is '
              'the worst. Quartiles cut the ranking into four equal groups; the app colours the '
              'best quarter green and the worst red only where "better" has a plain direction.',
          'percentile of a country = share of countries with a lower value × 100',
          '#150 of 179 on a "lower is better" indicator: 149 countries have higher values and 29 '
              'lower, so it sits in the best quarter (16th percentile by value).',
        ),
        _Term(
          'Standard deviation',
          'How far values typically sit from the mean. Small: countries are alike. Large: they '
              'are spread out.',
          's = √( Σ(xᵢ − mean)² ÷ (n − 1) )',
          'Values 2, 4, 4, 4, 5, 5, 7, 9: mean 5, s ≈ 2.14.',
        ),
      ]
    ),
    (
      'Change',
      [
        _Term(
          'Percent change',
          'How much a value grew relative to where it started.',
          'change % = (new − old) ÷ old × 100',
          '50 → 60 is +20 %. 60 → 50 is −16.7 %, not −20 %: the base is different.',
        ),
        _Term(
          'Percentage points (pp)',
          'The plain difference between two percentages. Do not mix it with percent change.',
          'change pp = new % − old %',
          'Unemployment 10 % → 12 % is +2 pp, which is also +20 % in relative terms.',
        ),
        _Term(
          'Average annual growth (CAGR)',
          'The steady yearly rate that would take the first value to the last one.',
          'CAGR = (last ÷ first)^(1 ÷ years) − 1',
          '100 → 150 over 10 years: (1.5)^(0.1) − 1 ≈ 4.1 % a year.',
        ),
        _Term(
          'Change since the first reading',
          'The caption under a country chart compares the latest value with the first one '
              'shown, not with last year.',
          'Δ = latest − first (in the indicator\'s own unit, or pp for shares)',
          'A series that starts at 9.3 and ends at 9.2 reads "−0.1 since" its first year.',
        ),
      ]
    ),
    (
      'Rates and money',
      [
        _Term(
          'Rates per 1,000 or per 100,000',
          'Counts divided by the population at risk, so countries of different size compare. '
              'Rare events use 100,000 to avoid tiny decimals.',
          'rate = events ÷ population × 1,000 (or × 100,000)',
          '50 deaths of children under five per 10,000 births = 5 per 1,000 births.',
        ),
        _Term(
          'Per capita',
          'A national total divided by the number of residents.',
          'per capita = total ÷ population',
          'GDP of \$2 trillion and 50 million people → \$40,000 per person.',
        ),
        _Term(
          'Current vs constant prices',
          'Current prices include inflation; constant (real) prices remove it, so growth means '
              'more goods and services, not higher prices.',
          'real = nominal ÷ price index × 100',
          'Nominal GDP +8 % with 5 % inflation ≈ +2.9 % real growth (1.08 ÷ 1.05 − 1).',
        ),
        _Term(
          'PPP (purchasing power parity)',
          'Converts money using what the same basket of goods costs in each country, not the '
              'market exchange rate — a fairer comparison of living standards.',
          'GDP in PPP \$ = GDP in local currency ÷ PPP conversion factor',
          'Where prices are low, GDP per person in PPP \$ is higher than at market rates.',
        ),
        _Term(
          'Logarithmic scale',
          'Equal distances mean equal ratios. Used for money and population, where values span '
              '×1,000 and a plain axis would crush most countries into a line.',
          'position ∝ log₁₀(value)',
          '1,000 → 10,000 → 100,000 sit at equal steps.',
        ),
      ]
    ),
    (
      'Uncertainty',
      [
        _Term(
          'Sampling error and margin of error',
          'A survey asks a sample, not everyone. Another sample would give a slightly different '
              'share. The margin of error says how far off it may be.',
          'MoE (95 %) ≈ 1.96 × √( p × (1 − p) ÷ n )',
          'p = 50 %, n = 1,000 → ±3.1 pp. With n = 250 it is ±6.2 pp.',
        ),
        _Term(
          '95 % confidence interval',
          'Estimate ± margin of error. The method catches the true value in 95 of 100 samples. '
              'On survey charts it is the shaded band around the line.',
          'CI = estimate ± 1.96 × standard error',
          '42 % ± 3 pp → somewhere between 39 % and 45 %.',
        ),
        _Term(
          'Design effect',
          'Real surveys sample villages or streets, not random individuals; people near each '
              'other answer alike, so the true error is larger than the simple formula.',
          'real MoE = simple MoE × √deff (deff often 1.5–2)',
          '±3.1 pp with deff 2 → about ±4.4 pp.',
        ),
        _Term(
          'Is a difference real?',
          'Two survey results differ for sure only if the gap is larger than the combined error.',
          'gap is significant if |p₁ − p₂| > 1.96 × √(SE₁² + SE₂²)',
          '45 % vs 41 %, each ±3.1 pp (SE ≈ 1.6): needed gap ≈ 4.4 pp → 4 pp is not proven.',
        ),
        _Term(
          'Measured vs modelled',
          'Some numbers are counted (registers, censuses); others are estimated by a model where '
              'counts are missing — WHO and UN mortality estimates often are. Model estimates move '
              'when the model is revised, and neighbouring years are smoothed.',
          '—',
          'A perfectly smooth series for a country with weak death registration is a sign of a model.',
        ),
        _Term(
          'Forecasts',
          'IMF figures for the current and later years are projections, revised twice a year. '
              'The app shades them on charts.',
          '—',
          'Treat a projection as a forecast, not a fact.',
        ),
      ]
    ),
    (
      'Trends and relationships',
      [
        _Term(
          'Why a trend line is shown — or not',
          'The app draws a straight trend only when the series really moves one way: at least 6 '
              'readings, a Mann–Kendall test with p < 0.05, and the same direction in both halves. '
              'Up-then-down series get no line, because one line would lie about them.',
          'all three tests must pass',
          'A series that rises, dips for two years and rises again: "no steady trend".',
        ),
        _Term(
          'Mann–Kendall test',
          'Compares every pair of years: does the later value rise more often than it falls? '
              'p is the chance of a pattern this strong if there were no trend at all.',
          'S = Σ sign(xⱼ − xᵢ) over all pairs i < j',
          'p < 0.05: fewer than 1 in 20 trendless series would look this one-sided.',
        ),
        _Term(
          'Theil–Sen slope',
          'The steepness of the trend line: the median of the slopes between every pair of '
              'points, so one odd year cannot tilt it.',
          'slope = median of (xⱼ − xᵢ) ÷ (tⱼ − tᵢ)',
          'Slopes 0.2, 0.3, 0.3, 0.4, 2.0 → 0.3 per year, not the 0.64 a mean would give.',
        ),
        _Term(
          'LOWESS smoothing',
          'For long series (20+ readings) a soft curve through the points shows the shape '
              'without forcing a straight line.',
          'a weighted local regression around each point',
          'On a long life-expectancy series the curve shows where gains sped up or slowed.',
        ),
        _Term(
          'Correlation is not causation',
          'Two indicators can move together because a third thing drives both, or by chance. '
              'Correlation r runs from −1 to +1; 0 means no straight-line link.',
          'r = Σ(x − x̄)(y − ȳ) ÷ √( Σ(x − x̄)² × Σ(y − ȳ)² )',
          'Richer countries report higher happiness; money is one cause among health, trust and freedom.',
        ),
      ]
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics basics',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                  'The terms and formulas behind the numbers in this app — tap a term for its '
                  'formula and a worked example.',
                  style: TextStyle(fontSize: 13, color: kTextDim, height: 1.4)),
              const SizedBox(height: 12),
              for (final s in _sections) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                  child: Text(s.$1.toUpperCase(),
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: kAmber)),
                ),
                for (final t in s.$2) _TermCard(t),
              ],
              const SizedBox(height: 16),
              chartWatermark,
            ],
          ),
        ),
      ),
    );
  }
}

class _Term {
  final String name, plain, formula, example;
  const _Term(this.name, this.plain, this.formula, this.example);
}

class _TermCard extends StatelessWidget {
  final _Term t;
  const _TermCard(this.t);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: kAmber,
          collapsedIconColor: kTextDim,
          title: Text(t.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          children: [
            Text(t.plain, style: const TextStyle(fontSize: 13, height: 1.4)),
            if (t.formula != '—') ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: kAmber.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(t.formula,
                    style: const TextStyle(fontSize: 13, fontFamily: 'Menlo', height: 1.35)),
              ),
            ],
            const SizedBox(height: 10),
            Text('Example', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kTextDim)),
            const SizedBox(height: 2),
            Text(t.example, style: TextStyle(fontSize: 13, color: kTextDim, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
