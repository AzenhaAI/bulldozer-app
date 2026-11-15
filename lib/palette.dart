import 'package:flutter/material.dart';

import 'theme.dart';

/// Region colour palette shared by the editorial charts (scatter, bubbles, dot
/// strips, group trends). Bars and choropleths stay amber (ranking / scale);
/// region hues are only for grouping.
///
/// The hues follow the Okabe–Ito colour-blind-safe set (amber, sky blue,
/// bluish green, vermillion, reddish purple) plus a violet and a neutral grey,
/// so Americas (brand amber) and Africa (vermillion) no longer blur together.
/// Each region has a bright tone for the dark theme and a deeper tone for the
/// light theme, both readable (≥ 3:1) on the page background.
const Map<String, Color> _regionDark = {
  'Europe & Central Asia': Color(0xFF56B4E9), // sky blue
  'Americas': Color(0xFFF59E0B), // brand amber
  'East Asia & Pacific': Color(0xFF2BB58C), // bluish green
  'South Asia': Color(0xFFA78BFA), // violet
  'Middle East & North Africa': Color(0xFFE07BB5), // reddish purple
  'Sub-Saharan Africa': Color(0xFFE5602A), // vermillion
  'Advanced / other': Color(0xFF94A3B8), // grey
  // Gapminder 4-region names
  'Europe': Color(0xFF56B4E9),
  'Asia': Color(0xFF2BB58C),
  'Africa': Color(0xFFE5602A),
};

const Map<String, Color> _regionLight = {
  'Europe & Central Asia': Color(0xFF0072B2),
  'Americas': Color(0xFFB57800),
  'East Asia & Pacific': Color(0xFF00876A),
  'South Asia': Color(0xFF7354C9),
  'Middle East & North Africa': Color(0xFFB0458A),
  'Sub-Saharan Africa': Color(0xFFC94F0C),
  'Advanced / other': Color(0xFF64748B),
  'Europe': Color(0xFF0072B2),
  'Asia': Color(0xFF00876A),
  'Africa': Color(0xFFC94F0C),
};

/// Region → colour for the active theme.
Map<String, Color> get regionColor => isLight ? _regionLight : _regionDark;

/// Colour for regions not in the palette (and missing regions).
Color get kRegionOther =>
    isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

Color colorFor(String? region) =>
    (region != null ? regionColor[region] : null) ?? kRegionOther;

/// Regions present in [regions], in the site's canonical order, for a legend.
List<String> legendRegions(Iterable<String> regions) {
  const order = [
    'Europe & Central Asia',
    'Americas',
    'East Asia & Pacific',
    'South Asia',
    'Middle East & North Africa',
    'Sub-Saharan Africa',
    'Europe',
    'Asia',
    'Africa',
    'Advanced / other',
  ];
  final present = regions.toSet();
  return [
    for (final r in order)
      if (present.contains(r)) r,
  ];
}
