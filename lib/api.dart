import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'offline_bundle.dart';

/// The Flutter app is a thin client over the BullDozer site's JSON endpoints,
/// same pattern as the Ativa app over its own static JSON.
// Overridable at build time (--dart-define=BD_BASE=…) so a dead host can
// stand in for "no connection" when testing the offline states.
const kBaseUrl = String.fromEnvironment('BD_BASE', defaultValue: 'https://azenha.ai/bulldozer');

/// Where a *person* is sent. Deliberately not kBaseUrl: the data still lives on
/// the old host because the parser feeds only that one, but no tap out of the
/// app may land there. Links move now, fetches move when the pipeline does.
const kSiteUrl = 'https://azenha.ai/bulldozer';

/// A site page opened inside the app's own browser view, marked so the site
/// knows: it then hides its App Store prompt ("Get the app" — seen inside the
/// app, 23 Oct 2026) and its phone tab bar, and remembers that for the rest of
/// the visit. Pages outside BullDozer (Model Lab) pass through unchanged.
String inAppSite(String url) {
  if (!url.startsWith(kSiteUrl)) return url;
  final i = url.indexOf('#');
  final base = i < 0 ? url : url.substring(0, i);
  final frag = i < 0 ? '' : url.substring(i);
  return '$base${base.contains('?') ? '&' : '?'}app=1$frag';
}

Directory? _cacheDir;

Future<File?> _cacheFile(String path) async {
  if (kIsWeb) return null; // no filesystem cache on web
  try {
    _cacheDir ??= await getApplicationCacheDirectory();
    return File('${_cacheDir!.path}/${cacheNameFor(path)}');
  } catch (_) {
    return null;
  }
}

/// Fetches JSON with a read-through file cache: network-first, falling back to
/// the last cached copy when offline. Fresh responses are cached for next time.
Future<dynamic> fetchJson(String path) async {
  final file = await _cacheFile(path);
  try {
    final r = await http
        .get(Uri.parse('$kBaseUrl$path'))
        .timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) {
      throw Exception('HTTP ${r.statusCode} for $path');
    }
    final body = utf8.decode(r.bodyBytes);
    // Decode BEFORE caching: a captive portal or CDN error page served as 200
    // used to get persisted first, and every offline launch after that threw
    // from the fallback below until a fresh valid response overwrote it.
    final parsed = jsonDecode(body);
    if (file != null) {
      file.writeAsString(body).ignore(); // cache for offline, fire-and-forget
    }
    return parsed;
  } catch (e) {
    if (file != null && await file.exists()) {
      try {
        return jsonDecode(await file.readAsString()); // offline fallback
      } on FormatException {
        file.delete().ignore(); // poisoned by an older, less careful version
      }
    }
    // Nothing cached for this page: unpack the copy baked into the app once,
    // then read it from the cache like any other offline page.
    if (file != null && _cacheDir != null && await OfflineBundle.seed(_cacheDir!) && await file.exists()) {
      return jsonDecode(await file.readAsString());
    }
    rethrow;
  }
}

/// One-paragraph Wikipedia summary for a place name (REST API). Returns null on
/// any miss (unmatched title, offline) — the caller just omits the blurb.
Future<String?> fetchWikipediaSummary(String name) async {
  try {
    final r = await http
        .get(Uri.parse(
            'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(name)}'))
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) return null;
    final j = jsonDecode(utf8.decode(r.bodyBytes));
    final extract = j['extract'];
    return (extract is String && extract.isNotEmpty) ? extract : null;
  } catch (_) {
    return null;
  }
}

class Observation {
  final String entity;
  final String group;
  final String period;
  final double value;
  final String iso;

  /// 95% margin of error (survey series; the site's scripts/tools/moe.py), or null.
  final double? moe;

  Observation.fromJson(Map<String, dynamic> j)
      : moe = (j['moe'] as num?)?.toDouble(),
        entity = j['entity'] ?? '',
        group = j['group'] ?? '',
        period = '${j['period'] ?? ''}',
        value = (j['value'] as num?)?.toDouble() ?? 0,
        iso = j['iso'] ?? '';
}

class Dataset {
  final String slug;
  final String title;
  final String summary;
  final String unit;
  final String source;
  final String license;
  /// The publisher's own page, and the one-line method note the site shows on
  /// the dataset page (weighting, item, projection caveat) — empty when absent.
  final String url, method, vintage;
  final List<Observation> data;

  /// 'pp' (shares, scores) or 'pct' (levels); empty when the site does not say.
  final String changeMode;

  /// First projected year (IMF WEO), drawn dashed and left out of trends.
  final double? projectedFrom;

  /// Countries measured in different years (household surveys): compare each
  /// country's latest reading, not one calendar year.
  final bool latestPerCountry;

  Dataset.fromJson(Map<String, dynamic> j)
      : changeMode = j['changeMode'] ?? '',
        latestPerCountry = j['latestPerCountry'] == true,
        projectedFrom = double.tryParse('${j['projectedFrom'] ?? ''}'),
        slug = j['slug'] ?? '',
        title = j['title'] ?? '',
        summary = j['summary'] ?? '',
        unit = j['unit'] ?? '',
        source = j['source'] ?? '',
        license = j['license'] ?? '',
        url = j['url'] ?? '',
        method = j['method'] ?? '',
        vintage = j['vintage'] ?? '',
        data = [
          for (final o in (j['data'] as List? ?? [])) Observation.fromJson(o)
        ];

  List<String> get periods =>
      {for (final o in data) o.period}.toList()..sort();

  /// Median per period over the countries measured in every period (the same
  /// rule as the site's regional lines): a changing set of countries would
  /// show who was surveyed, not change. Null with fewer than 3 such countries.
  ({List<(String, double)> points, int n})? panelMedians() {
    final ps = periods;
    final byEnt = <String, Map<String, double>>{};
    for (final o in data) {
      (byEnt[o.iso.isEmpty ? o.entity : o.iso] ??= {})[o.period] = o.value;
    }
    final panel = [for (final m in byEnt.values) if (ps.every(m.containsKey)) m];
    if (panel.length < 3) return null;
    double med(List<double> v) {
      v.sort();
      final n = v.length;
      return n.isOdd ? v[n ~/ 2] : (v[n ~/ 2 - 1] + v[n ~/ 2]) / 2;
    }

    return (points: [for (final p in ps) (p, med([for (final m in panel) m[p]!]))], n: panel.length);
  }

  /// Median across countries in one period — the chart's reference line.

  /// For [latestPerCountry] series, the median of each country's latest
  /// reading (a 2020 median would be mostly the rich countries surveyed then).
  ({double value, int n})? medianIn(String period) {
    final List<double> v;
    if (latestPerCountry) {
      final latest = <String, Observation>{};
      for (final o in data) {
        final k = o.iso.isEmpty ? o.entity : o.iso;
        if (!latest.containsKey(k) || o.period.compareTo(latest[k]!.period) > 0) latest[k] = o;
      }
      v = [for (final o in latest.values) if (o.value.isFinite) o.value]..sort();
    } else {
      v = [for (final o in data) if (o.period == period && o.value.isFinite) o.value]..sort();
    }
    if (v.isEmpty) return null;
    final n = v.length;
    return (value: n.isOdd ? v[n ~/ 2] : (v[n ~/ 2 - 1] + v[n ~/ 2]) / 2, n: n);
  }
}

Future<Dataset> fetchDataset(String slug) async =>
    Dataset.fromJson(await fetchJson('/data/$slug.json') as Map<String, dynamic>);

class CountryItem {
  final String slug;
  final String title;
  final String topic;
  final String kind; // 'macro' | 'survey'
  final String unit;
  final double value;
  final String period;
  final int rank;
  final int total;
  /// This country's earliest period and how many it has: 1 is a single figure
  /// with no trend, 0 is unknown (data published before 2 Nov 2026).
  final String first;
  final int years;
  /// 'high' or 'low' where one direction is plainly better, '' where the rank
  /// is no judgement (opinions, spending, population) — testers, 2 Nov 2026.
  final String better;

  CountryItem.fromJson(Map<String, dynamic> j)
      : slug = j['slug'] ?? '',
        title = j['title'] ?? '',
        topic = j['topic'] ?? '',
        kind = j['kind'] ?? 'macro',
        unit = j['unit'] ?? '',
        value = (j['value'] as num?)?.toDouble() ?? 0,
        period = '${j['period'] ?? ''}',
        rank = j['rank'] ?? 0,
        total = j['total'] ?? 0,
        first = j['first'] is String ? j['first'] : '',
        years = j['years'] is int ? j['years'] : 0,
        better = '${j['better'] ?? ''}';
}

class Country {
  final String iso;
  final String name;
  final String official; // official long-form name, '' when same as [name]
  final String region;
  final List<CountryItem> items;

  Country.fromJson(Map<String, dynamic> j)
      : iso = j['iso'] ?? '',
        name = j['name'] ?? '',
        official = j['official'] ?? '',
        region = j['region'] ?? '',
        items = [
          for (final i in (j['items'] as List? ?? [])) CountryItem.fromJson(i)
        ];
}

Future<List<Country>> fetchCountryIndex() async => [
      for (final c in await fetchJson('/data/country-index.json') as List)
        Country.fromJson(c)
    ];

/// Static per-country metadata for the country header (capital pre-projected
/// into the app map's geo space, coat-of-arms URL, currency, ISO-2 code).
class CountryMeta {
  final String a2;
  final String capital;
  final double? capX; // capital in the 1000×500 map space, null if unknown
  final double? capY;
  final String coa; // coat-of-arms image URL ('' when missing)
  final String curCode;
  final String curName;
  final String curSymbol;

  CountryMeta.fromJson(Map<String, dynamic> j)
      : a2 = j['a2'] ?? '',
        capital = j['capital'] ?? '',
        capX = (j['capX'] as num?)?.toDouble(),
        capY = (j['capY'] as num?)?.toDouble(),
        coa = j['coa'] ?? '',
        curCode = j['curCode'] ?? '',
        curName = j['curName'] ?? '',
        curSymbol = j['curSymbol'] ?? '';
}

Map<String, CountryMeta>? _countryMetaCache;

Future<Map<String, CountryMeta>> fetchCountryMeta() async {
  if (_countryMetaCache != null) return _countryMetaCache!;
  final j = await fetchJson('/data/country-meta.json') as Map<String, dynamic>;
  return _countryMetaCache = {
    for (final e in j.entries)
      e.key: CountryMeta.fromJson(e.value as Map<String, dynamic>)
  };
}

class Story {
  final String slug;
  final String tag;
  final String title;
  final String dek;

  Story.fromJson(Map<String, dynamic> j)
      : slug = j['slug'] ?? '',
        tag = j['tag'] ?? '',
        title = j['title'] ?? '',
        dek = j['dek'] ?? '';

  String get url => '$kSiteUrl/stories/$slug/';
}

Future<List<Story>> fetchStories() async => [
      for (final s in await fetchJson('/data/stories.json') as List)
        Story.fromJson(s)
    ];

class Release {
  final String name;
  final String window; // human-readable, e.g. "April & October"
  final List<int> months; // typical release months (1–12)
  final String kind;
  final String url;

  Release.fromJson(Map<String, dynamic> j)
      : name = j['name'] ?? '',
        window = j['window'] ?? '',
        months = [for (final m in (j['months'] as List? ?? [])) m as int],
        kind = j['kind'] ?? 'macro',
        url = j['url'] ?? '';
}

Future<List<Release>> fetchReleases() async => [
      for (final r in await fetchJson('/data/releases.json') as List)
        Release.fromJson(r)
    ];

/// A most-valuable brand (BrandZ/Forbes aggregate) — for the Biz section.
class Brand {
  final int rank;
  final String name;
  final double valueBn;
  final int year;
  final String iso;
  final String logo; // Commons SVG; append ?width=N for a PNG render
  final String desc;
  final String wiki;

  Brand.fromJson(Map<String, dynamic> j)
      : rank = (j['rank'] as num?)?.toInt() ?? 0,
        name = j['name'] ?? '',
        valueBn = (j['valueBn'] as num?)?.toDouble() ?? 0,
        year = (j['year'] as num?)?.toInt() ?? 0,
        iso = j['iso'] ?? '',
        logo = j['logo'] ?? '',
        desc = j['desc'] ?? '',
        wiki = j['wiki'] ?? '';

  /// A PNG render of the (usually SVG) logo at [w] px — Commons Special:FilePath.
  String logoUrl(int w) => logo.isEmpty ? '' : '$logo?width=$w';
}

Future<List<Brand>> fetchBrands() async => [
      for (final b in await fetchJson('/data/brands.json') as List)
        Brand.fromJson(b)
    ];

/// One city in a livability metric.
class City {
  final String city, country, cc;
  final double value;
  City.fromJson(Map<String, dynamic> j)
      : city = j['city'] ?? '',
        country = j['country'] ?? '',
        cc = j['cc'] ?? '',
        value = (j['value'] as num?)?.toDouble() ?? 0;
}

/// A city-livability metric (one dimension) with its ranked cities.
class CityMetric {
  final String key, label, unit, summary;
  final List<City> data;
  CityMetric.fromJson(Map<String, dynamic> j)
      : key = j['key'] ?? '',
        label = j['label'] ?? '',
        unit = j['unit'] ?? '',
        summary = j['summary'] ?? '',
        data = [for (final c in (j['data'] as List? ?? [])) City.fromJson(c)];
}

/// Cities dataset: title/source + a list of metrics (dimensions).
class CitiesData {
  final String title, source;
  final List<CityMetric> metrics;
  CitiesData.fromJson(Map<String, dynamic> j)
      : title = j['title'] ?? '',
        source = j['source'] ?? '',
        metrics = [
          for (final m in (j['metrics'] as List? ?? []))
            CityMetric.fromJson(m)
        ];
}

Future<CitiesData> fetchCities() async =>
    CitiesData.fromJson(await fetchJson('/data/cities.json') as Map<String, dynamic>);

class QuizCountry {
  final String name;
  final String region;
  final String flag;
  final List<String> facts;

  QuizCountry.fromJson(Map<String, dynamic> j)
      : name = j['name'] ?? '',
        region = j['region'] ?? '',
        flag = j['flag'] ?? '',
        facts = [for (final f in (j['facts'] as List? ?? [])) '$f'];
}

Future<List<QuizCountry>> fetchQuizPool() async => [
      for (final c in await fetchJson('/data/quiz-pool.json') as List)
        QuizCountry.fromJson(c)
    ];

String formatValue(double v) {
  final abs = v.abs();
  if (abs >= 1e12) return '${(v / 1e12).toStringAsFixed(1)}T';
  if (abs >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
  if (abs >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
  if (abs >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  if (abs >= 100) return v.toStringAsFixed(0);
  if (abs >= 10) return v.toStringAsFixed(1);
  return v.toStringAsFixed(2);
}
