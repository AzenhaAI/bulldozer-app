# Apple App Store — step by step (BullDozer)

Unlike Android, the final upload package cannot be pre-built without the paid
account: the `.ipa` is produced at Archive time once a paid team is selected.

| | |
|---|---|
| Bundle ID | `com.shpara.bulldozerApp` |
| Display name | BullDozer |
| App Store name | BullDozer — World in Numbers |
| Version | 1.28.0+44 |
| Deployment target | iOS 13.0 |
| Devices | iPhone only (iPad dropped for the first release) |
| Category | Education |
| Privacy policy | https://shpara.com/bulldozer/privacy/ |
| Support URL | https://shpara.com/bulldozer/support/ |
| Public contact | azenha.agent@gmail.com |

## Decisions already taken

- **Individual enrolment, not Organization.** The activity is registered under
  a personal name, so a D-U-N-S would be issued to that same name and Apple
  would show it as the seller anyway — Organization buys nothing but delay.
  The $99/year fee is identical for both types; there is no free tier (the
  waiver exists only for nonprofits, education and government).
- **iPhone only.** `TARGETED_DEVICE_FAMILY = "1"`. iPad would need its own
  13" screenshot set and adds an untested review surface. One line to restore.
- **Export compliance pre-declared.** `ITSAppUsesNonExemptEncryption = false`
  in `Info.plist` — the app uses only standard HTTPS, so App Store Connect
  will stop asking on every upload.

## 1. Apple Developer Program (once)

1. Apple Developer app on iPhone, or https://developer.apple.com/programs/enroll/
2. Sign in with the Apple ID, two-factor authentication required.
3. Choose **Individual**.
4. Identity verification: government document plus a selfie, in the app.
   Same rules as Google — no editing of the image, all corners visible,
   daylight, no flash.
5. Pay **$99/year** (auto-renewing; can be turned off in account settings).
6. Approval usually takes 24–48 hours.

## 2. Point the project at the paid team

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Runner target → **Signing & Capabilities** → select the paid team,
   replacing the free personal team `ARY46X758B`.
3. Leave "Automatically manage signing" ON — Xcode creates the distribution
   certificate and provisioning profile.

## 3. Create the app record

https://appstoreconnect.apple.com → **My Apps → +** → New App:
- Platform **iOS**
- Name `BullDozer — World in Numbers`
- Primary language English (U.S.)
- Bundle ID `com.shpara.bulldozerApp` (register it under Certificates,
  Identifiers & Profiles first if it does not appear in the list)
- SKU `bulldozer` (internal, never shown publicly)

## 4. Build and upload

```sh
flutter build ipa --release
```

Open `build/ios/archive/Runner.xcarchive` in **Xcode → Organizer** →
**Distribute App → App Store Connect → Upload**. The build takes 10–30 minutes
to finish processing before it can be attached to a version.

## 5. Listing

Texts come from `store/listing.md`. Apple has fields Play does not:
- **Subtitle** (30 chars) — write one, e.g. "World statistics, explored"
- **Keywords** (100 chars, comma-separated, no spaces after commas)
- **Promotional text** (170 chars, editable without a new build)

Screenshots must match Apple's exact sizes: **6.9"** (1320×2868) and/or
**6.5"** (1284×2778). Minimum 3 per required size. Wrong dimensions are the
most common mechanical rejection.

App Privacy → **Data Not Collected** (true: no analytics or ad SDK in the
app). Age rating questionnaire → 4+.

## 6. EU trader status

Apple requires a trader declaration for EU distribution. Declaring **trader**
publishes name, physical address, phone and email on the product page — with
an Individual account that means a home address. The apps are free, carry no
ads and no purchases; whether that qualifies as non-trader is a legal
self-declaration to make deliberately, not a checkbox to click past.

## 7. Submit

Attach the processed build → **Submit for Review**. Review usually takes 1–3
days. **Apple has no 12-tester rule** — that requirement is Google's alone.
TestFlight is optional.

## Rejection risks worth knowing

- **Guideline 4.2 Minimum Functionality** — apps that read as a website
  wrapper get rejected. BullDozer is fully native Flutter with local caching,
  which is the honest description to give the reviewer.
- **Guideline 5.1.1** — the privacy policy must be reachable and must match
  the App Privacy answers. It does.
- **Screenshot dimensions** — see section 5.
