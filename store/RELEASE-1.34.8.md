# Release 1.34.8 (67) — iOS and Android together

Build 67 = 66 plus a one-time consent before the first Ask AI question leaves the
phone ("Send this question to an AI?" · Not now / Allow), App Store guideline
5.1.2(i), the same dialog AlfaCat has. Screenshots and videos from 66 still show
the app as it is (the dialog appears only once, before the first question).

Media, on branch `appstore-prep`:
- iPhone 6.9" screenshots: `store/screenshots/ios-6.9-66/` (8, 1320×2868)
- Play phone screenshots: `store/screenshots/android-play-66/` (8, 1080×1920)
- App Store videos: `store/appstore-video/` — header 3840×1646, search 3840×2560,
  App Preview 886×1920 (27 s, silent stereo track); recipe in `_recipe/`
- Texts: `store/ios/fields/` — whatsnew, description and promo mention Ask AI;
  review notes describe the consent and the privacy label

## App Store
1. **Create the version** (a person's step): App Store Connect → BullDozer →
   iOS App → "+" → `1.34.8`.
2. Then, through the API (Claude can run these):
   - `push_fields.sh bulldozer_app com.shpara.bulldozerApp` — What's New,
     description, promo, review notes
   - `push_screenshots.py 6797664814 1.34.8 …/ios-6.9-66 APP_IPHONE_67`
   - `push_previews.py 6797664814 1.34.8 …/app-preview-iphone-886x1920-en.mp4 IPHONE_65` (as AlfaCat)
   - attach build 67 to the version
3. **App Privacy** (by hand): App Privacy → Edit → add **Other User Content** →
   used for **App Functionality** · not linked to identity · not used for
   tracking. Without it the label says "Data Not Collected", which Ask AI makes
   untrue.
4. **Header and search videos** (by hand): Product Page Information → upload
   `header-video-3840x1646-en.mp4` and `search-video-3840x2560-en.mp4`.
5. Submit for review. Release manually, together with Android.

## Google Play
1. Closed testing → new release → AAB `store/android/bulldozer-v1.34.8+67.aab`;
   release notes = `store/ios/fields/whatsnew.txt` (485 characters, under 500).
2. Store listing → phone screenshots from `android-play-66`.
3. **Data safety** — see check 2 in `PLAY-production-application-v5.md`
   (Other user-generated content, optional, ephemeral, App functionality).
4. Production application: paste v5 answers **on or after Wednesday 14 October**
   (day 14), after re-reading the tester count.

## Already live (no store review needed)
- azenha.ai/bulldozer/privacy says the app asks once before the first question.
- bot.azenha.ai: every figure now carries "among the highest / lowest / upper,
  middle, lower third" in words; before, Peru's 20.7% hypertension (lowest of
  194) came back as "extremely high".
