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
- Tallies: `screen.<name>`, `nav.<from>.<to>`, `session.start`, `time.sec`,
  `visit.<bucket>`, `content.dataset.<catalog slug>`,
  `content.country.<ISO alpha-2>`, `feature.<name>`, `activation.first_chart`.
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

## 2. App Store Connect → App Privacy (replaces "Data Not Collected")

`store/ios/APPSTORE-listing.md` currently says **Data Not Collected**. That
stops being true with this release.

- Data Types → **Usage Data** → **Product Interaction**.
  - Purpose: **Analytics** (only).
  - Linked to the user's identity: **No**.
  - Used for tracking: **No**.
- No other data types change.
- No ATT prompt. No privacy-manifest change: no new SDK, and the module uses
  no required-reason API (it stores one string through the existing
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

After approval, update `store/PLAY-STEPS.md` to match.

## Separate items to know about (not created by this change)

- The app opens some azenha.ai pages in the external browser (menu links).
  Those pages load GA4 and Clarity; see the README's "Separate blocker". They
  open outside the app, so they do not change the in-app declaration, but the
  site still needs its consent banner.
- The web build of the app cannot reach the ingest endpoint: the Worker sends
  no CORS headers, so a browser blocks the POST. The module drops this quietly
  (it treats it as offline). Only matters if the web build is ever published.
