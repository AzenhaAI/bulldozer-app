# Production access — third application, v6 (submit from Wednesday 14 October)

v6 = v5 with three answers rewritten to say what was shipped while the Play
test ran: 16 versions since August and the App Store release. Every number is
traced in "Where the numbers come from" at the end. v5 is kept as it was.

BullDozer Stats · `ai.azenha.bulldozer`. Same rules as the application that
passed for Madeira Ativa: every number checkable, nothing rounded up, nothing a
tester did not say. Evidence: `PLAY-tester-feedback-log.md` (per tester, dated,
their words, the build that answered each item).

## Before you paste — four checks
1. **Upload AAB 67 (1.34.8) to the closed track first.** The answers say every
   item is answered "in the build now in the track". File:
   `store/android/bulldozer-v1.34.8+67.aab` (signature checked against Play).
   67 = 66 plus a one-time "Send this question to an AI?" consent before the
   first Ask AI question leaves the phone.
2. **Data safety form.** Ask AI sends the question and a country code to our
   server and to Anthropic. The form must say so before "as stated in the Data
   safety form" is true: App activity → **Other user-generated content** →
   Collected: yes · Shared: no (Anthropic and Cloudflare process it for us as
   service providers) · Processed ephemerally: yes · Required or optional:
   **optional** (the user can decline in the consent dialog) · Purpose: **App
   functionality**. Encrypted in transit: yes. Deletion request: not needed,
   nothing is stored.
3. **Testers installed.** The answers say 13 — read today's number in Play
   Console (Testing → Closed testing → Testers) and change it if different.
4. **Wait for day 14** of this round (Wednesday) before submitting.

---

## How did you recruit users for your closed test?  *(261)*
```
The same circle that tests our other apps: friends and acquaintances, asked one by one over Telegram and WhatsApp, no paid provider. Each gave the Google account on their phone; we added it to the track and sent the opt-in link with install steps. 13 installed.
```

## Describe the engagement you received from testers  *(276)*
```
13 installed on their own phones. Testers wrote in directly, often with screenshots marked in red: seven requests and reports between 11 Sep and 2 Oct, each logged with date and wording. All seven are answered in builds now in the track; release notes name the screens to try.
```

## Summary of the feedback, and how you collected it  *(284)*
```
Logged per tester with date and their words. Requests: causes of death, where new data lands, more open surveys, an Ask AI per country, menu on every tab. Reports: the globe turned against the finger sideways; coastlines broke at the globe's edge. Content and UX, no crashes reported.
```

## What changed as a result of testing  *(279)*
```
From testers: Ask AI per country, then answers in words with every number checked against our data and a Beta label; menu on every tab; globe follows the finger and ends cleanly at the edge; WHO causes of death; badges for new data. Also: small-phone fixes, forecasts marked est.
```

## Who is the intended audience?  *(259)*
```
Students, analysts, journalists and anyone who needs to check a figure about a country and see where it stands in the world: GDP, life expectancy, democracy, opinion surveys, school results and 260 other indicators for 232 countries. Free, no account, no ads.
```

## How does your app provide value?  *(265)*
```
One place for public country statistics otherwise spread across the IMF, World Bank, WHO, Pew, IEA and others. Every figure shows its source, year and licence and is checked against the publisher. Profiles, rankings, Ask AI summaries; what was loaded works offline.
```

**Expected installs** — "Hundreds in the first months; growth through the
website, the Telegram bot and the App Store version that already exist."

## Production readiness  *(278)*
```
Ready. The same app has been on the App Store since August; 1.34.8 is in review there now. 13 testers installed, and all 7 items they raised are fixed in build 67, now in the track. No account, no ads; the only data sent is an Ask AI question, and only after the user allows it.
```

## What did you do differently this time?  *(286)*
```
We kept shipping while we waited: 16 versions since August (1.28 to 1.34.8, 22 iOS builds), and the same app has been live on the App Store since August. Each tester item is logged with date, their words and the build that fixed it: 7 items, all fixed. Data grew from 186 to 273 series.
```

---

## Evidence (from the feedback log)

| # | Date | Tester | Request / report | Answered in |
|---|------|--------|------------------|-------------|
| 1 | 11 Sep | relayed | Causes of death by country | WHO series + story, Sep |
| 2 | 15 Sep | Alexey | Where did the new data appear? | NEW badges, builds 55–56 |
| 3 | 15 Sep | relayed | Which open surveys are missing? | CSES, Afrobarometer, IEA; then LAPOP, Pew, ISSP |
| 4 | 27 Sep | relayed | Why no Ask AI? | Ask AI 57; AI answers 59; Beta 61 |
| 5 | 27 Sep | relayed | Menu only on Home | every tab, 58 |
| 6 | 2 Oct | Alexander | Globe turns against the finger sideways | 62 |
| 7 | 2 Oct | Alexander | Artefacts at the globe's edge | 62 |

Not counted: R5 (country codes in Ask AI) — its source is not confirmed.
Found by us while answering: child mortality shown ten times too low; menu
opening the wrong tab (57); profile tiles cut on small phones (63); IMF
forecasts shown as results (63); bars card unreadable in light theme (64).

## Where the numbers come from (checked 14 October)

- **App Store since August:** App Store Connect API — version 1.28.0 created
  3 Aug and Ready for Sale; 1.29 created 18 Aug, Ready for Sale; 1.34.8 created
  12 Oct, Waiting for Review, release set to manual (same day as Android).
- **Live App Store updates:** one (1.29), plus 1.34.8 in review. The other
  versions went to TestFlight and the Play closed track, not to the App Store —
  so the answers say "16 versions" and "22 iOS builds", never "16 App Store
  updates".
- **16 versions since August:** 1.28.0, 1.29, 1.30, 1.31.0, 1.32.0, 1.33.0,
  1.33.1, 1.34.0 … 1.34.8 (git: version bumps in pubspec.yaml).
- **22 iOS builds:** builds 44–67 uploaded 3 Aug – 12 Oct (52 and 56 never
  went to Apple), App Store Connect API.
- **7 tester items:** rows A1, X1, X2, R1–R4 of `PLAY-tester-feedback-log.md`;
  R5 left out, its source is not on record.
- **Not written as tester feedback:** our own fixes (small phones, est. labels,
  consent dialog, child-mortality units, reply language). They appear only after
  "Also:", never as something a tester said.
