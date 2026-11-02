# Production access — fourth application, v9 (build 75)

BullDozer Stats · `ai.azenha.bulldozer`. v6 was rejected (~16 Oct); this round
ran with builds 67–75. v7 (build 72) and v8 (build 73) are kept as they were;
v9 adds build 75 and R15–R17 (2 Nov). Every number below is traced in the feedback log
(`PLAY-tester-feedback-log.md`): 19 tester items, A1, X1–X2, R1–R4, R6–R17
(R5 left out — its source is not on record). 17 fixed, 2 planned (R6 partly
answered by R11/R13, R7 model choice).

## Before you paste — four checks
1. **Build 75 (1.38.1) in the closed track and reviewed** —
   `store/android/bulldozer-v1.38.1+75.aab`, signature 49:E8:57:CC… Answers 4
   and 7 say "build 75, now in the track". Build 74 went to TestFlight only.
2. **Which builds reached the track this round.** Answers 2 and 8 say testers
   received builds 67 to 75. Read Test and release → Latest releases and bundles:
   if some (68–73) were never uploaded, change "eight builds, 67 to 75" to the
   real list and "builds testers received" stays true only for those.
3. **Testers.** Dashboard → the closed-test card: opted-in count and day count.
   The answers say 13; change it in answers 1 and 7 if different.
4. **Day 14** of this round has passed (Saturday 31 October).

---

## 1. How did you recruit users for your closed test?  *(261)*
```
The same circle that tests our other apps: friends and acquaintances, asked one by one over Telegram and WhatsApp, no paid provider. Each gave the Google account on their phone; we added it to the track and sent the opt-in link with install steps. 13 installed.
```

## 2. Describe the engagement you received from testers  *(262)*
```
Testers used the app and wrote back, often with screenshots: 19 requests and reports from 11 Sep to 2 Nov, logged with date and their words. 17 are fixed in builds testers received, most within days; the other two are planned. Each build's notes say what to try.
```

## 3. Summary of the feedback, and how you collected it  *(282)*
```
Logged per tester, dated, in their words. Asked for: Ask AI, AI news and reads, image and video AI, poster maps, people charts, source and method under each figure. Reported: globe turned the wrong way, raw errors on a weak signal, stale figures, keyboard over the menu. No crashes.
```

## 4. What changes did you make to your app based on what you learned during your closed test?  *(237)*
```
Ask AI with checked figures and consent; AI lists and an image/video guide; Map and People chart makers; source, year and method under each figure; trends marked; offline data; clear No connection states; freshest figure first. Build 75.
```

## 5. Who is the intended audience?  *(259)*
```
Students, analysts, journalists and anyone who needs to check a figure about a country and see where it stands in the world: GDP, life expectancy, democracy, opinion surveys, school results and 270 other indicators for 232 countries. Free, no account, no ads.
```

## 6. How does your app provide value?  *(273)*
```
One place for public country statistics otherwise spread across the IMF, World Bank, WHO, Pew, IEA and others. Every figure shows its source, year and licence; data refresh weekly and a guard stops a source from losing years. Ask AI, poster maps and people charts, offline.
```

**Expected installs** — the smallest range offered.

## 7. Production readiness  *(253)*
```
Ready. The same app has been on the App Store since August; 1.34.8 is live there. 13 testers installed; 17 of the 19 items they raised are fixed in build 75, now in the track. No account, no ads; an Ask AI question is sent only after the user allows it.
```

## 8. What did you do differently this time?  *(257)*
```
This round we answered testers in days, not weeks: eight builds, 67 to 75, each fixing what they had just reported, and every item logged with date and their words. We also found why figures went stale: the weekly refresh was not being published. Now it is.
```

---

## Where the numbers come from
- **19 items, 17 fixed:** feedback log rows A1, X1, X2, R1–R4, R6–R17. Open:
  R6 (AI block — partly answered by the lists in R11/R13), R7 (model choice).
- **App Store since August:** 1.28.0 created 3 Aug, Ready for Sale; 1.34.8
  Ready for Sale since 12 Oct (App Store Connect API, checked 2 Nov).
- **Builds 67–75:** iOS builds up to 75 uploaded 12 Oct – 2 Nov (App Store
  Connect); Android 74 was never built — the Play track gets 75; Android AABs in
  `store/android` and `_superseded/`. Play track contents — check 2 above.
- **Weekly refresh:** GitHub Actions "Update data", every Monday, all runs
  green; publication to azenha.ai was manual and lagged until 28 Oct.
  "Now it is" in answer 8 holds only while every Monday refresh is published —
  by hand, or by the publish job once it is approved.
