import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asking for a rating, on Apple's terms rather than ours.
///
/// Two different things live here and they are not interchangeable:
///
/// * The *system* prompt ([quizFinished], [datasetClosed]). iOS draws it, the
///   rating is given without leaving the app, and iOS decides whether to draw
///   it at all — three times a year per user, and there is no way to find out
///   what it did. So the call is fire-and-forget: never gate anything on it,
///   never follow it with "did that work?", never show our own dialog as a
///   fallback. A hand-rolled "rate us" box with buttons is against the
///   guidelines.
///
/// * [openStoreListing] opens the store page. No quota, because a person
///   pressed the "Rate BullDozer" menu row to get there.
///
/// When (1.40, agreed 16 Nov 2026): only a returning reader — the 3rd launch
/// or later, at least 3 days after this build first ran — and only at a calm
/// moment that went well:
/// * a quiz round finished with a good score;
/// * an indicator closed after a chart was shared or a CSV saved
///   ([goodMoment] marks those, for 3 days; the prompt waits until the
///   reader is back on the app's own screens);
/// * an indicator closed once 5 or more have been read (open 15 s or more).
/// Never while a link from outside is taking the reader somewhere ([hold]).
/// Never on the first launch, never over a sheet or an error, never as a gate.
/// Our own cap is once per 90 days, under the platforms' own quotas.
/// 1.39 asked after the third finished quiz, once per install; an install
/// asked then counts as asked when 1.40 first runs.
class AskReview {
  /// Did the share sheet send something? A dismissed sheet is not a share.
  /// Android reports `unavailable` on systems that cannot say.
  static bool shared(ShareResult r) =>
      r.status == ShareResultStatus.success ||
      (defaultTargetPlatform == TargetPlatform.android && r.status == ShareResultStatus.unavailable);

  static const _kLaunches = 'review_launches';
  static const _kFirstSeen = 'review_first_seen';
  static const _kLastAsked = 'review_last_asked';
  static const _kGood = 'review_good_at'; // when; expires after goodDays
  static const _kGoodLegacy = 'review_good_moment'; // 1.40 drafts: a bool
  static const _kOpened = 'review_datasets_opened';
  static const _kLegacyAsked = 'review_asked'; // 1.39: asked once, no date

  static const minLaunches = 3;
  static const minDays = 3;
  static const minDatasets = 5;
  static const capDays = 90;
  static const goodDays = 3;
  static const minRead = Duration(seconds: 15);

  static final _plugin = InAppReview.instance;
  static bool _asking = false; // two pages closing at once ask once
  static DateTime? _openedAt; // the indicator page on screen
  static DateTime? _quietUntil;

  /// A link from outside is moving the reader (pages close under it): do not
  /// ask for the next few seconds.
  static void hold([Duration d = const Duration(seconds: 3)]) =>
      _quietUntil = DateTime.now().add(d);

  /// A good moment marked at [at] still counts at [now].
  static bool fresh(DateTime? at, DateTime now) =>
      at != null && now.difference(at).inDays < goodDays && !now.isBefore(at);

  /// The rule, apart from storage and the plugin (tested on its own).
  static bool eligible({
    required DateTime now,
    required int launches,
    required DateTime? firstSeen,
    required DateTime? lastAsked,
  }) {
    if (launches < minLaunches || firstSeen == null) return false;
    if (now.difference(firstSeen).inDays < minDays) return false;
    return lastAsked == null || now.difference(lastAsked).inDays >= capDays;
  }

  /// Called once per launch, from main().
  static Future<void> noteLaunch() async {
    try {
      final p = await SharedPreferences.getInstance();
      final now = DateTime.now();
      if (!p.containsKey(_kFirstSeen)) await p.setString(_kFirstSeen, now.toIso8601String());
      if ((p.getBool(_kLegacyAsked) ?? false) && !p.containsKey(_kLastAsked)) {
        await p.setString(_kLastAsked, now.toIso8601String());
      }
      await p.setInt(_kLaunches, (p.getInt(_kLaunches) ?? 0) + 1);
    } catch (_) {}
  }

  /// A chart shared or a CSV saved. The prompt itself waits for the next calm
  /// moment, when the reader closes the indicator page.
  static Future<void> goodMoment() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kGood, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  /// A finished quiz round. [good]: the reader got most answers right.
  static Future<void> quizFinished({required bool good}) async {
    if (good) await _ask();
  }

  /// An indicator page opened.
  static void datasetOpened() => _openedAt = DateTime.now();

  /// An indicator page closed: the reader is back in the app with nothing
  /// over it. It counts as read after [minRead]; a glance from a link does not.
  static Future<void> datasetClosed() async {
    try {
      final now = DateTime.now();
      final p = await SharedPreferences.getInstance();
      final opened = _openedAt;
      _openedAt = null;
      if (opened != null && now.difference(opened) >= minRead) {
        await p.setInt(_kOpened, (p.getInt(_kOpened) ?? 0) + 1);
      }
      if (p.containsKey(_kGoodLegacy)) await p.remove(_kGoodLegacy);
      final good = fresh(DateTime.tryParse(p.getString(_kGood) ?? ''), now);
      if (good || (p.getInt(_kOpened) ?? 0) >= minDatasets) await _ask();
    } catch (_) {}
  }

  static Future<void> _ask() async {
    final quiet = _quietUntil;
    if (quiet != null && DateTime.now().isBefore(quiet)) return;
    if (_asking) return;
    _asking = true;
    try {
      final p = await SharedPreferences.getInstance();
      final now = DateTime.now();
      if (!eligible(
        now: now,
        launches: p.getInt(_kLaunches) ?? 0,
        firstSeen: DateTime.tryParse(p.getString(_kFirstSeen) ?? ''),
        lastAsked: DateTime.tryParse(p.getString(_kLastAsked) ?? ''),
      )) {
        return;
      }
      if (!await _plugin.isAvailable()) return;
      await p.setString(_kLastAsked, now.toIso8601String());
      await p.remove(_kGood);
      await _plugin.requestReview();
    } catch (_) {
    } finally {
      _asking = false;
    }
  }

  /// The menu row. Opens the store page with the review sheet already up.
  static Future<void> openStoreListing() =>
      _plugin.openStoreListing(appStoreId: '6797664814');
}
