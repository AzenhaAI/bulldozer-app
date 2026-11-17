// Tests for usage_stats.dart. Copy next to the module as test/usage_stats_test.dart
// (import adjusted to this package).
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bulldozer_app/usage_stats.dart';

// Audience (aud.*) and period (active.*) counters are tested separately.
Map strip(Object? counts) =>
    Map.of(counts as Map)
      ..removeWhere((k, _) => (k as String).startsWith('aud.') || k.startsWith('active.'));

List days(Map<String, dynamic> body) => [
      for (final d in body['days'] as List)
        {'day': d['day'], 'active': d['active'], 'counts': strip(d['counts'])},
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String? stored;
  late List<Map<String, dynamic>> sent;
  late int status;
  late DateTime now;

  Future<void> start({
    bool existing = false,
    String? keep,
    Future<String?> Function()? source,
    Map<String, List<String>> experiments = const {},
  }) async {
    stored = keep;
    await UsageStats.init(
      app: 'ativa',
      version: '1.9.8',
      read: () async => stored,
      write: (s) async => stored = s,
      existingUser: existing,
      installSource: source,
      experiments: experiments,
      platform: 'ios',
      now: () => now,
      client: MockClient((req) async {
        sent.add(jsonDecode(req.body) as Map<String, dynamic>);
        return http.Response('', status);
      }),
    );
    await UsageStats.flush();
  }

  setUp(() {
    sent = [];
    status = 204;
    now = DateTime(2026, 11, 16, 10);
  });

  test('new install sends install day and opened flag, no identifier', () async {
    await start();
    expect(sent, hasLength(1));
    final b = sent.single;
    expect(b['install_day'], '2026-11-16');
    expect(days(b), [
      {'day': '2026-11-16', 'active': true, 'counts': {'session.start': 1}},
    ]);
    expect(b.keys.toSet(), {'app', 'platform', 'version', 'install_day', 'days'});
  });

  test('opened flag goes once per day; events still flow', () async {
    await start();
    UsageStats.screen('map');
    UsageStats.event('onboarding.done');
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await UsageStats.flush();
    final last = sent.last['days'] as List;
    expect(last.single['active'], false);
    expect(strip(last.single['counts']), {'screen.map': 1, 'onboarding.done': 1});

    now = DateTime(2026, 11, 17, 9);
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await UsageStats.flush();
    expect((sent.last['days'] as List).single['active'], true);
  });

  test('existing user has no install day', () async {
    await start(existing: true);
    expect(sent.single['install_day'], isNull);
  });

  test('server outage keeps tallies for a later retry', () async {
    status = 503;
    await start();
    UsageStats.event('feature.route_planned', 2);
    await UsageStats.flush();
    expect(sent, hasLength(2));
    status = 204;
    await UsageStats.flush();
    final days = sent.last['days'] as List;
    expect(days.single['active'], true);
    expect(strip(days.single['counts']), {'session.start': 1, 'feature.route_planned': 2});
    sent.clear();
    await UsageStats.flush();
    expect(sent, isEmpty);
  });

  test('state survives a restart', () async {
    status = 503;
    await start();
    UsageStats.event('feature.x');
    await UsageStats.flush();
    final saved = stored;
    status = 204;
    sent.clear();
    await start(keep: saved);
    expect(sent.single['install_day'], '2026-11-16');
    expect(strip((sent.single['days'] as List).single['counts']), {'session.start': 2, 'feature.x': 1});
  });

  test('opt-out sends nothing and drops pending', () async {
    status = 503;
    await start();
    await UsageStats.setEnabled(false);
    UsageStats.event('feature.x');
    status = 204;
    sent.clear();
    await UsageStats.flush();
    expect(sent, isEmpty);
    await UsageStats.setEnabled(true);
  });

  test('transitions, content ids, time and sessions', () async {
    await start();
    sent.clear();
    UsageStats.screen('home');
    UsageStats.screen('map');
    UsageStats.screen('map');
    UsageStats.content('levada', 'PR-1 Vereda');
    now = now.add(const Duration(minutes: 3));
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await UsageStats.flush();
    final c = (sent.last['days'] as List).single['counts'] as Map;
    expect(c['nav.home.map'], 1);
    expect(c.containsKey('nav.map.map'), false);
    expect(c['content.levada.pr_1_vereda'], 1);
    expect(c['time.sec'], 180);
    expect(c['visit.m1_5'], 1);

    // Back within 30 minutes: same session.
    now = now.add(const Duration(minutes: 10));
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    // Away for 40 minutes: a new session.
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 40));
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await UsageStats.flush(); // may join a flush already in flight
    await UsageStats.flush();
    final c2 = (sent.last['days'] as List).single['counts'] as Map;
    expect(c2['session.start'], 1);
  });

  test('install source and experiment arm travel as cohort tags', () async {
    await start(source: () async => 'Flyer A6!', experiments: {'home': ['a', 'b']});
    final tags = sent.single['tags'] as Map;
    expect(tags['source'], 'flyer_a6_');
    expect(['a', 'b'], contains(tags['exp_home']));
    expect(UsageStats.variant('home'), tags['exp_home']);
    // Kept across restarts, never re-rolled.
    final saved = stored;
    sent.clear();
    await start(keep: saved, experiments: {'home': ['a', 'b']});
    expect((sent.single['tags'] as Map)['exp_home'], tags['exp_home']);
  });

  test('existing users carry no tags', () async {
    await start(existing: true, source: () async => 'x');
    expect(sent.single.containsKey('tags'), false);
  });

  test('funnel steps count once per install; audience once a day', () async {
    await start();
    sent.clear();
    UsageStats.funnel('onboarding', 'language_picked');
    UsageStats.funnel('onboarding', 'language_picked');
    await UsageStats.flush();
    final c = (sent.last['days'] as List).single['counts'] as Map;
    expect(c['funnel.onboarding.language_picked'], 1);
    expect(c.keys.where((k) => (k as String).startsWith('aud.lang.')), isEmpty,
        reason: 'audience was sent with the first batch of the day');
  });

  test('uncaught errors are counted by type and location only', () async {
    await start();
    sent.clear();
    final prev = FlutterError.onError;
    FlutterError.onError = (_) {};
    UsageStats.catchErrors();
    FlutterError.onError!(FlutterErrorDetails(
      exception: RangeError('secret user text'),
      stack: StackTrace.fromString('#0      MapPage.build (package:bulldozer/map_page.dart:412:7)'),
    ));
    FlutterError.onError = prev;
    await UsageStats.flush();
    final c = (sent.last['days'] as List).single['counts'] as Map;
    expect(c['error.rangeerror.map_page_412'], 1);
    expect(jsonEncode(sent.last).contains('secret'), false);
  });

  test('active.week and active.month once per period', () async {
    await start(); // Mon 16 Nov 2026
    var c = (sent.last['days'] as List).single['counts'] as Map;
    expect(c['active.week'], 1);
    expect(c['active.month'], 1);
    // Wednesday, same week and month: nothing new.
    now = DateTime(2026, 11, 18, 9);
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await UsageStats.flush();
    await UsageStats.flush();
    c = (sent.last['days'] as List).single['counts'] as Map;
    expect(c.containsKey('active.week'), false);
    // Next Monday: a new week, same month.
    now = DateTime(2026, 11, 23, 9);
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await UsageStats.flush();
    await UsageStats.flush();
    c = (sent.last['days'] as List).single['counts'] as Map;
    expect(c['active.week'], 1);
    expect(c.containsKey('active.month'), false);
    // 1 December: a new week and month.
    now = DateTime(2026, 12, 1, 9);
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await UsageStats.flush();
    await UsageStats.flush();
    c = (sent.last['days'] as List).single['counts'] as Map;
    expect(c['active.week'], 1);
    expect(c['active.month'], 1);
  });

  test('bad names are ignored', () async {
    await start();
    UsageStats.event('Has Spaces');
    UsageStats.event('user@example.com');
    sent.clear();
    await UsageStats.flush();
    expect(sent, isEmpty);
  });
}
