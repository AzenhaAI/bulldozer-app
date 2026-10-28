# Production access — fourth application, v7 (submit on or after Saturday 31 October)

BullDozer Stats · `ai.azenha.bulldozer`. v6 was rejected (~16 Oct); this round
ran with builds 67–72. Every number below is traced in the feedback log
(`PLAY-tester-feedback-log.md`): 15 tester items, A1, X1–X2, R1–R4, R6–R13
(R5 left out — its source is not on record). 13 fixed, 2 planned (R6 partly
answered by R11/R13, R7 model choice).

## Before you paste — four checks
1. **Build 72 (1.37.1) in the closed track and reviewed** —
   `store/android/bulldozer-v1.37.1+72.aab`, signature 49:E8:57:CC… Answer 7
   says "build 72, now in the track".
2. **Which builds reached the track this round.** Answers 2 and 8 say testers
   received builds 67 to 72. Read Test and release → Latest releases and bundles:
   if some (68–71) were never uploaded, change "six builds, 67 to 72" to the
   real list and "builds testers received" stays true only for those.
3. **Testers.** Dashboard → the closed-test card: opted-in count and day count.
   The answers say 13; change it in answers 1 and 7 if different.
4. **Day 14** of this round must have passed (Saturday).

---

## 1. How did you recruit users for your closed test?  *(261)*
```
The same circle that tests our other apps: friends and acquaintances, asked one by one over Telegram and WhatsApp, no paid provider. Each gave the Google account on their phone; we added it to the track and sent the opt-in link with install steps. 13 installed.
```

## 2. Describe the engagement you received from testers  *(263)*
```
Testers used the app and wrote back, often with screenshots: 15 requests and reports from 11 Sep to 28 Oct, logged with date and their words. 13 are fixed in builds testers received, most within days; the other two are planned. Each build's notes say what to try.
```

## 3. Summary of the feedback, and how you collected it  *(276)*
```
Logged per tester with date and their words. Asked for: Ask AI, AI news and long reads, image and video AI, poster maps, offline use, model choice. Reported: globe turned the wrong way, raw errors on a weak signal, stale figures (Argentina showed two populations). No crashes.
```

## 4. What changes did you make to your app based on what you learned during your closed test?  *(262)*
```
Ask AI with checked figures; a consent step; AI news, long reads and image/video AI lists; Map maker in Edu; every dataset kept on the phone for offline use; plain No connection states; one freshest figure per country; globe fixed. 1.34.8 to 1.37.1 in the track.
```

## 5. Who is the intended audience?  *(259)*
```
Students, analysts, journalists and anyone who needs to check a figure about a country and see where it stands in the world: GDP, life expectancy, democracy, opinion surveys, school results and 270 other indicators for 232 countries. Free, no account, no ads.
```

## 6. How does your app provide value?  *(272)*
```
One place for public country statistics otherwise spread across the IMF, World Bank, WHO, Pew, IEA and others. Every figure shows its source, year and licence; data refresh weekly and a guard stops a source from losing years. Ask AI, poster maps, and it all works offline.
```

**Expected installs** — the smallest range offered.

## 7. Production readiness  *(253)*
```
Ready. The same app has been on the App Store since August; 1.34.8 is live there. 13 testers installed; 13 of the 15 items they raised are fixed in build 72, now in the track. No account, no ads; an Ask AI question is sent only after the user allows it.
```

## 8. What did you do differently this time?  *(253)*
```
This round we answered testers in days, not weeks: six builds, 67 to 72, each fixing what they had just reported, and every item logged with date and their words. We also fixed the weekly data refresh so the site and app never show a stale figure again.
```

---

## Where the numbers come from
- **15 items, 13 fixed:** feedback log rows A1, X1, X2, R1–R4, R6–R13. Open:
  R6 (AI block — partly answered by the lists in R11/R13), R7 (model choice).
- **App Store since August:** 1.28.0 created 3 Aug, Ready for Sale; 1.34.8
  Ready for Sale since mid-October (App Store Connect API, 14 Oct).
- **Builds 67–72:** iOS builds 67–72 uploaded 12–28 Oct (App Store Connect);
  Android AABs in `store/android` and `_superseded/`. Play track contents —
  check 2 above.
- **Weekly refresh:** GitHub Actions "Update data", every Monday, all runs
  green; publication to azenha.ai was manual and lagged until 28 Oct.
