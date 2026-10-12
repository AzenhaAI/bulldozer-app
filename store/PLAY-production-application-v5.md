# Production access — third application (deadline: Wednesday 14 October)

BullDozer Stats · `ai.azenha.bulldozer`. Same rules as the application that
passed for Madeira Ativa: every number checkable, nothing rounded up, nothing a
tester did not say. Evidence: `PLAY-tester-feedback-log.md` (per tester, dated,
their words, the build that answered each item).

## Before you paste — four checks
1. **Upload AAB 66 (1.34.7) to the closed track first.** The answers say every
   item is answered "in the build now in the track". File:
   `store/android/bulldozer-v1.34.7+66.aab` (signature checked against Play).
2. **Data safety form.** Ask AI sends the question and a country code to our
   server and to Anthropic. The form must say so (Other user-generated content
   → collected, not shared for advertising, processed for app functionality,
   not linked to identity) before "as stated in the Data safety form" is true.
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

## What changed as a result of testing  *(287)*
```
Ask AI: answers written from our figures, every number checked, Beta label. Globe follows the finger, clean edge. Menu on every tab. Small-phone fixes; forecasts marked est. Data 186 to 273 series: WHO causes of death, Pew 2022-25, LAPOP, ISSP, TIMSS, each checked against the publisher.
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

## Production readiness  *(273)*
```
Ready. 13 testers installed; every request and report from the test is answered in the build now in the track. The same app is on the App Store after review. No account, no ads; the only data sent is an Ask AI question, as stated in the privacy policy and Data safety form.
```

## What did you do differently this time?  *(287)*
```
This time each tester's feedback is logged with dates and their own words, and each item names the build that answered it. The track now has the current build, not the summer one, with new screenshots. Seven requests and reports, all answered; data 186 to 273 series, all source-checked.
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
