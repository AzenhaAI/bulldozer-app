# Production access — fourth application, v8 (build 73)

BullDozer Stats · `ai.azenha.bulldozer`. v6 was rejected (~16 Oct); this round
ran with builds 67–73. v7 (build 72) is kept as it was; v8 adds build 73 and
R14. Every number below is traced in the feedback log
(`PLAY-tester-feedback-log.md`): 16 tester items, A1, X1–X2, R1–R4, R6–R14
(R5 left out — its source is not on record). 14 fixed, 2 planned (R6 partly
answered by R11/R13, R7 model choice).

## Before you paste — four checks
1. **Build 73 (1.38.0) in the closed track and reviewed** —
   `store/android/bulldozer-v1.38.0+73.aab`, signature 49:E8:57:CC… Answers 4
   and 7 say "build 73, now in the track". If 73 is not uploaded yet, use v7.
2. **Which builds reached the track this round.** Answers 2 and 8 say testers
   received builds 67 to 73. Read Test and release → Latest releases and bundles:
   if some (68–72) were never uploaded, change "seven builds, 67 to 73" to the
   real list and "builds testers received" stays true only for those.
3. **Testers.** Dashboard → the closed-test card: opted-in count and day count.
   The answers say 13; change it in answers 1 and 7 if different.
4. **Day 14** of this round has passed (Saturday 31 October).

---

## 1. How did you recruit users for your closed test?  *(261)*
```
The same circle that tests our other apps: friends and acquaintances, asked one by one over Telegram and WhatsApp, no paid provider. Each gave the Google account on their phone; we added it to the track and sent the opt-in link with install steps. 13 installed.
```

## 2. Describe the engagement you received from testers  *(263)*
```
Testers used the app and wrote back, often with screenshots: 16 requests and reports from 11 Sep to 28 Oct, logged with date and their words. 14 are fixed in builds testers received, most within days; the other two are planned. Each build's notes say what to try.
```

## 3. Summary of the feedback, and how you collected it  *(280)*
```
Logged per tester with date and their words. Asked for: Ask AI, AI news and long reads, image and video AI, poster maps, people charts, offline use, model choice. Reported: globe turned the wrong way, raw errors on a weak signal, stale figures (two populations shown). No crashes.
```

## 4. What changes did you make to your app based on what you learned during your closed test?  *(261)*
```
Ask AI with checked figures and consent; AI news and image/video AI lists plus a guide; Map maker and People chart makers in Edu; all data kept on the phone for offline use; plain No connection states; one freshest figure per country; globe fixed. Now build 73.
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
Ready. The same app has been on the App Store since August; 1.34.8 is live there. 13 testers installed; 14 of the 16 items they raised are fixed in build 73, now in the track. No account, no ads; an Ask AI question is sent only after the user allows it.
```

## 8. What did you do differently this time?  *(257)*
```
This round we answered testers in days, not weeks: seven builds, 67 to 73, each fixing what they had just reported, and every item logged with date and their words. We also found why figures went stale: the weekly refresh was not being published. Now it is.
```

---

## Where the numbers come from
- **16 items, 14 fixed:** feedback log rows A1, X1, X2, R1–R4, R6–R14. Open:
  R6 (AI block — partly answered by the lists in R11/R13), R7 (model choice).
- **App Store since August:** 1.28.0 created 3 Aug, Ready for Sale; 1.34.8
  Ready for Sale since 12 Oct (App Store Connect API, checked 2 Nov).
- **Builds 67–73:** iOS builds up to 73 uploaded 12–29 Oct, 73 processed
  (VALID) on 29 Oct (App Store Connect API, 2 Nov); Android AABs in
  `store/android` and `_superseded/`. Play track contents — check 2 above.
- **Weekly refresh:** GitHub Actions "Update data", every Monday, all runs
  green; publication to azenha.ai was manual and lagged until 28 Oct.
  "Now it is" in answer 8 holds only while every Monday refresh is published —
  by hand, or by the publish job once it is approved.
