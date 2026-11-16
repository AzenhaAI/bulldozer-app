# Anonymous usage statistics: privacy texts (DRAFT, not sent)

Status: **draft only.** Nothing here has been entered in App Store Connect,
Play Console or the website. Each change needs Kirill's explicit word, and
goes out with the first release that contains the analytics code
(`lib/usage.dart`, `lib/usage_stats.dart`).

Source of truth for the wording: `~/Projects/_stores/usage/README.md`,
"Store declarations".

## What the app does (for whoever approves this)

- Once a day it sends one batch to `https://usage.azenha.ai/v1/batch`
  (Cloudflare Worker, D1 database in the EU): app, platform, app version,
  install date (day only; `null` for installs that predate analytics),
  whether the app was opened that day, and daily tallies.
- New installs also send cohort tags: `source` (the channel that brought
  the install, see below). No experiments run, so there are no `exp_*` tags.
- Tallies: `screen.<name>`, `nav.<from>.<to>`, `session.start`, `time.sec`,
  `visit.<bucket>`, `content.dataset.<catalog slug>`,
  `content.country.<ISO alpha-2>`, `feature.<name>`, `activation.first_chart`,
  `funnel.<flow>.<step>` (once per install: quiz, ask, map, share),
  `aud.lang.<code>`, `aud.form.phone|tablet`, `aud.theme.dark|light`,
  `aud.text.normal|large` (once a day), and
  `error.<type>.<file>_<line>` for uncaught Dart errors (never the message).
- Install source: on Android, `utm_source` from the Google Play Install
  Referrer API (`google-play` for organic installs); otherwise the `src`
  parameter of the link the app was first opened with; else `unknown`.
  It is read once, on the first run, and sent as a cohort tag only.
- No identifier of any kind. No IP address, user agent or request log is
  kept. Nothing the reader types becomes part of a name.
- Menu → "Share anonymous usage statistics" (on by default). Switching it off
  stops counting and deletes the unsent tallies.

## 1. Privacy policy paragraph (BullDozer page on azenha.ai; add PT/RU translations)

> **Anonymous usage statistics.** The app counts, per day, which screens
> and features were used and whether the app was opened. It also stores
> its install date on your device. It sends these counts to our server
> (Cloudflare, EU) without any identifier: no device ID, account, IP
> address or advertising ID is stored. We use the totals only to improve
> the app. You can turn this off in the menu -> Share anonymous usage
> statistics.

Note: BullDozer has no separate Settings screen; the switch sits in the side
menu (the drawer opened from the top-right button). The README's wording says
"Settings ->"; above it is adapted to "the menu ->".

**Proposed addition (not in the README; for Kirill to accept or drop).** The
README paragraph predates error counts, install source and audience
counts. A policy that says only "which screens and features were used" now
under-describes what is sent. Suggested sentence after the first one:

> It also counts app errors (the kind of error and where in the app's code
> it happened, never its content), coarse device settings (app language,
> phone or tablet, dark or light theme, large text) and, on the first run,
> the channel the app was installed from (for example a Google Play
> campaign).

## 2. App Store Connect → App Privacy (replaces "Data Not Collected")

`store/ios/APPSTORE-listing.md` currently says **Data Not Collected**. That
stops being true with this release.

- Data Types → **Usage Data** → **Product Interaction**.
  - Purpose: **Analytics**.
  - Linked to the user's identity: **No**.
  - Used for tracking: **No**.
- Data Types → **Diagnostics** → **Crash Data** (for `catchErrors()`).
  - Purposes: **App Functionality** and **Analytics**.
  - Linked to the user's identity: **No**.
  - Used for tracking: **No**.
- No other data types change.
- No ATT prompt. No privacy-manifest change on iOS: no new SDK there
  (`play_install_referrer` is Android-only), and the module uses no
  required-reason API (it stores one string through the existing
  `shared_preferences`).

After approval, update the "# App Privacy" section of
`store/ios/APPSTORE-listing.md` to match.

## 3. Google Play Console → Data safety (replaces "No data collected")

`store/PLAY-STEPS.md` currently says **No data collected / no data shared**.

- Does your app collect or share any of the required user data types? **Yes**.
- Is all of the user data collected by your app encrypted in transit? **Yes**.
- Do you provide a way for users to request that their data is deleted?
  Answer per the form's options: collection can be stopped in the app; nothing
  stored on the server is linked to a person.
- Data type: **App activity → App interactions**.
  - Collected: **Yes**. Shared: **No**.
  - Processed ephemerally: **No**.
  - Required or optional: **Optional** (users can turn it off).
  - Purpose: **Analytics**.
- Data type: **App info and performance → Crash logs** (for `catchErrors()`).
  - Collected: **Yes**. Shared: **No**.
  - Processed ephemerally: **No**.
  - Required or optional: **Optional**.
  - Purpose: **Analytics**.
- New SDK on Android: Google Play Install Referrer library
  (`com.android.installreferrer`, via the `play_install_referrer` package).
  It reads the referrer from the Play Store app on the device through a
  local service connection. The app forwards only `utm_source`,
  as part of the anonymous counts above, so no extra data type is declared.

After approval, update `store/PLAY-STEPS.md` to match.

## Separate items to know about (not created by this change)

- The app opens some azenha.ai pages in the external browser (menu links).
  Those pages load GA4 and Clarity; see the README's "Separate blocker". They
  open outside the app, so they do not change the in-app declaration, but the
  site still needs its consent banner.
- The web build of the app cannot reach the ingest endpoint: the Worker sends
  no CORS headers, so a browser blocks the POST. The module drops this quietly
  (it treats it as offline). Only matters if the web build is ever published.
