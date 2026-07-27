# Google Play — step by step (BullDozer)

Upload artifact: `store/android/bulldozer-v1.27.0.aab`
Package: `com.shpara.bulldozer_app` · version 1.27.0 (code 43)
Signed with YOUR upload key — `android/upload-keystore.jks`
(backup: `~/Documents/BullDozer_signing_keys/upload-keystore.jks`). Keep it forever.

> Account already exists and is verified — skip account creation, go to step 2.

## 1. Account (already done)
play.google.com/console — signed in, $25 paid, identity verified.

## 2. Create the app
1. Play Console → **Create app**.
2. Name: **BullDozer** · Default language: English (US) · Type: **App** · Free.
3. Accept the declarations.

## 3. Store listing (copy from `store/listing.md`)
- Short + full description (EN).
- App icon: 512×512 → `store/icon-512.png`.
- Feature graphic: 1024×500 → `store/feature-graphic-1024x500.png`.
- Phone screenshots: at least 2 (capture on the phone — see list in `listing.md`).
- Category: **Education**. Contact email: confirm which to expose.

## 4. Policy / content
- **Privacy policy URL**: `https://shpara.com/bulldozer/privacy`  ✅ LIVE (200)
- **Data safety** form: **No data collected / no data shared** (app only reads
  public JSON from shpara.com/bulldozer; no accounts, no ads, no tracking).
- Content rating questionnaire → **Everyone**.
- Target audience: 13+ (or all ages). No ads.

## 5. Upload the build
1. Left menu → **Testing ▸ Closed testing** → create a track.
2. Upload `store/android/bulldozer-v1.27.0.aab`.
3. On first upload, accept **Play App Signing** (Google keeps the release key;
   your upload key stays yours — correct).

## 6. The 12-tester rule (personal accounts)
Before Production, a personal account must run **closed testing with ≥12
testers for 14 continuous days**.
1. In the closed track add testers by email (or a Google Group).
2. Send them the opt-in link; they install and keep it 14 days.
3. After 14 days the **Apply for production** button unlocks.

> Tip: run BullDozer's closed test with the SAME 12 testers as Ativa, in
> parallel — one 14-day window covers both apps.

## 7. Production
Promote the closed track to Production → submit for review (a few days).

---
Artifact checklist: ✅ signed AAB · ✅ icon 512 · ✅ feature graphic ·
✅ privacy page LIVE · ✅ screenshots (5 phone, 880×1900, store/screenshots/) · ⬜ 12 testers
