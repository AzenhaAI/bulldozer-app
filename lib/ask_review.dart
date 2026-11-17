import 'package:in_app_review/in_app_review.dart';
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
///   ([goodMoment] marks those; the prompt waits for the share sheet to be
///   gone and the reader back in the app);
/// * an indicator closed once 5 or more have been opened.
/// Never on the first launch, never over a sheet or an error, never as a gate.
/// Our own cap is once per 90 days, under the platforms' own quotas.
/// 1.39 asked after the third finished quiz, once per install; an install
/// asked then counts as asked when 1.40 first runs.
class AskReview {
  static const _kLaunches = 'review_launches';
  static const _kFirstSeen = 'review_first_seen';
  static const _kLastAsked = 'review_last_asked';
  static const _kGood = 'review_good_moment';
  static const _kOpened = 'review_datasets_opened';
  static const _kLegacyAsked = 'review_asked'; // 1.39: asked once, no date

  static const minLaunches = 3;
  static const minDays = 3;
  static const minDatasets = 5;
  static const capDays = 90;

  static final _plugin = InAppReview.instance;

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
  /// moment: on Android the share call returns while the sheet is still up.
  static Future<void> goodMoment() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kGood, true);
    } catch (_) {}
  }

  /// A finished quiz round. [good]: the reader got most answers right.
  static Future<void> quizFinished({required bool good}) async {
    if (good) await _ask();
  }

  /// An indicator page opened.
  static Future<void> datasetOpened() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kOpened, (p.getInt(_kOpened) ?? 0) + 1);
    } catch (_) {}
  }

  /// An indicator page closed: the reader is back in the app with nothing
  /// over it.
  static Future<void> datasetClosed() async {
    try {
      final p = await SharedPreferences.getInstance();
      if ((p.getBool(_kGood) ?? false) || (p.getInt(_kOpened) ?? 0) >= minDatasets) await _ask();
    } catch (_) {}
  }

  static Future<void> _ask() async {
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
    } catch (_) {}
  }

  /// The menu row. Opens the store page with the review sheet already up.
  static Future<void> openStoreListing() =>
      _plugin.openStoreListing(appStoreId: '6797664814');
}
