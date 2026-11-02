# Production access — fourth application, v12 (build 77) — SUBMITTED 2 Nov 2026, ~16:10 UTC

Submitted by the developer while release 77 (submission #5) was still "In review" in the closed track.

BullDozer Stats · `ai.azenha.bulldozer`. v12 replaces v10/v11 after two findings on 2 Nov:
(1) Play Console's Submission activity shows the closed track received only builds 67 (12 Oct)
and 77 (2 Nov, in review) this round — 68–76 reached testers on iPhone via TestFlight only — so
every answer now matches that table; (2) an independent review (Fable 5.1) corrected overstated
words ("mostly with screenshots" → seven of 20; "tester's own wording" → "words as received";
"installed" → "opted in"; the Argentina check was ours, not a tester's) and removed sentences
that read as blaming the reviewer. No five-word phrase repeats v3–v9 (script). v9–v11 kept.

## Before you paste — four checks
1. **Release 77 must be Published in the closed track**, not "In review" (Publishing overview → Submission activity, #5). Answers 2, 4, 7, 8 say build 77 is in the track.
2. **13 testers:** read the opted-in count on the closed-test card; it is in answers 1 and 2.
3. **Dates:** "since 21 Aug" = submission #1 in Submission activity; "since 3 Aug" = App Store 1.28.0 created (API, 2 Nov).
4. **Android vitals:** nothing about crashes is asserted. If Play Console shows a crash-free figure worth quoting, read it there first.

---

## 1. How did you recruit users for your closed test?  *(281)*
```
People we know personally, each invited in a private Telegram or WhatsApp message. They told us which Google account their Android phone uses and got the opt-in link and a short note on installing. 13 opted in; many had tested our earlier apps and knew what a closed test involves.
```

## 2. Describe the engagement you received from testers  *(295)*
```
Closed track live since 21 Aug, 13 testers. They write by direct message, seven times with screenshots or example images: 20 requests and reports, 13 since 20 Oct, each kept with its date and the words as received. Fixes were tried first with testers on iPhone; build 77 brings them all to Play.
```

## 3. Summary of the feedback, and how you collected it  *(294)*
```
By direct message, translated from Russian, logged by date. Asked: "can I download the data and work offline?", "why no caption: how it is calculated, source, year?", "#5 of 120: good or bad?"; also poster maps, people charts, AI reading. Reported: raw error text on weak signal; stale figures.
```

## 4. What changes did you make to your app based on what you learned during your closed test?  *(299)*
```
We learned a figure without context gets misread. Build 77 captions each figure with publisher, year, licence and a method link, marks a single reading ("2024 only") apart from a trend ("2018 → 2025") and colours a rank only where better is clear; plus 514 files offline, map and people-chart tools.
```

## 5. Who is the intended audience?  *(275)*
```
Anyone who wants a fast, sourced answer about a country: students writing essays, journalists checking a claim, analysts comparing markets, teachers preparing a lesson. 273 indicators, 232 countries: economy, health, democracy, schooling, polls. Free, no sign-up, no adverts.
```

## 6. How does your app provide value?  *(279)*
```
Instead of opening a dozen statistics sites one by one, a user sees a country's figures in a single profile, each with publisher, year and licence. Source files are re-read from the publishers every Monday. Maps and people charts export as images with the source printed on them.
```

**Expected installs** — the smallest range offered.

## 7. Production readiness ("How did you decide that your app is ready?")  *(296)*
```
We judged it ready when the open list fell to two: 18 of 20 tester items are fixed in build 77; the two left (model picker, deeper Ask AI answers) are planned with them. The app has been public on Apple's App Store since 3 Aug, three releases there. No account, no ads; Ask AI asks consent first.
```

## 8. What did you do differently this time?  *(289)*
```
Our testers are unpaid volunteers, so instead of asking them to reinstall weekly we tried each fix on iPhone first and bundled them: 13 new reports from 20 Oct to 2 Nov, 11 fixed in code within a day, all in build 77 for Android. All logged with dates; two items stay planned with testers.
```

## Final free-text field (limit 300)

**Variant A — firm, the developer's points as facts** *(298)*
```
Fourth application. 13 unpaid volunteers, above the 12 required, have tested since 21 Aug; such a circle cannot be held for months, and it did its job: 18 of their 20 requests are closed and checked by them. Public on Apple's App Store since 3 Aug. If no again, please name exactly what fell short.
```

**Variant B — conciliatory (the reviewer's recommendation)** *(287)*
```
Fourth application. Since the last one: 13 new tester reports, 11 fixed within a day; fixes tried by the group on iPhone, then bundled into build 77. Public on Apple's App Store from 3 Aug. If the answer is again no, one concrete pointer to what fell short would let us fix it that week.
```

---

## Where the numbers come from
- **20 items, 18 fixed; 13 since 20 Oct, 11 fixed in code the same or next day:** feedback log A1, X1, X2, R1–R4, R6–R18 (R6–R18 this round; R8 20→21 Oct and R14 28→29 Oct next day, the rest same day). Open: R6, R7 — "planned with them" = decided with the testers, per the log.
- **13 above the 12 required:** Google's closed-testing rule is 12 opted-in testers for 14 days; the card shows the live count.
- **Seven with screenshots or example images:** X1, X2, R8, R10, R14, R15, R17.
- **Play track this round:** Submission activity — #4 12 Oct (build 67, 1.34.8), #5 2 Nov (build 77, 1.38.1). Earlier: #1–2 21 Aug, #3 27 Sep.
- **Builds 68–76:** iOS/TestFlight (App Store Connect); Android AABs built but not uploaded (68, 69, 70, 72, 73, 75) or uploaded and discarded unsent (76).
- **App Store:** 1.28.0 created 3 Aug, 1.29, 1.34.8 — all Ready for Sale (API, 2 Nov). 1.38.1 prepared with build 77, not submitted.
- **273 indicators, 232 countries, 514 offline files, 17 feeds:** catalogue, country index, bake script and bot `ai_news.js`, 2 Nov.
- **Every Monday:** GitHub Actions "Update data" re-parses the publishers' files; publishing to the site is still by hand.
