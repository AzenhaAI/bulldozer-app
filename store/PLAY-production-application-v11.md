# Production access — fourth application, v11 (build 77)

BullDozer Stats · `ai.azenha.bulldozer`. Every answer rewritten so that no five-word
phrase repeats v3–v9 (checked by script, 2 Nov). v9 and v10 are kept as they were; v11 = v10 for build 77. Answers 7–8
carry the developer's point: volunteers, two months of testing, the app public on
the App Store since August, and the delay holding the project back.

## Before you paste — four checks
1. **Build 77 (1.38.1) in the closed track** — `bulldozer-v1.38.1+77.aab` (76 was uploaded and discarded unsent), signature 49:E8:57:CC….
2. **"6 Android builds (68 to 77)"** in answer 4 assumes 68, 69, 70, 72, 73 and 77 reached the track (75 and 76 did not). Check Test and release → Latest releases and bundles and change the count if different.
3. **Testers:** answers 1 and 7 say 13 — read the closed-test card.
4. Round started 8 Oct; day 14 was 22 Oct.

---

## 1. How did you recruit users for your closed test?  *(280)*
```
Volunteers only: no paid testers and no testing service. We wrote to people we know personally, one by one, in Telegram and WhatsApp chats. Each sent the Gmail address used on their Android phone and got the opt-in link plus a short install guide. 13 joined and installed the app.
```

## 2. Describe the engagement you received from testers  *(278)*
```
In closed testing since September, three rounds. Testers sent 20 requests and bug reports, mostly with screenshots; 13 came this round, and 11 of those were fixed the same or the next day. Each is logged with its date and the tester's own wording; every build lists what to try.
```

## 3. Summary of the feedback, and how you collected it  *(272)*
```
Examples, translated: "can I download the data and work offline?", "why no caption: how it is calculated, source, year?", "#5 of 120, good or bad?", poster maps, NYT-style people charts, AI news and AI video. Bugs: raw error text on weak 5G, two populations for Argentina.
```

## 4. What changes did you make to your app based on what you learned during your closed test?  *(276)*
```
This round, 11 fixes in 6 Android builds (68 to 77): offline mode with all 514 data files inside; a map maker and a people-chart maker; AI reading list (5 tabs, 17 feeds); a guide to AI images and video; source, year, method and licence under each figure; honest rank colours.
```

## 5. Who is the intended audience?  *(275)*
```
Anyone who wants a fast, sourced answer about a country: students writing essays, journalists checking a claim, analysts comparing markets, teachers preparing a lesson. 273 indicators, 232 countries: economy, health, democracy, schooling, polls. Free, no sign-up, no adverts.
```

## 6. How does your app provide value?  *(252)*
```
Instead of opening a dozen statistics sites one by one, a user sees a country's figures in a single profile, each with publisher, year and licence. Data is re-parsed every Monday. Maps and people charts export as images with the source printed on them.
```

**Expected installs** — the smallest range offered.

## 7. Production readiness  *(272)*
```
Every rule followed: 13 opted-in testers, far past 14 days, every report answered. Build 77 in the closed track carries 18 of their 20 requests. Public in Apple's store since August, three releases there (1.28, 1.29, 1.34.8). No account, no ads; Ask AI asks consent first.
```

## 8. What did you do differently this time?  *(285)*
```
Our testers are volunteers, not paid, and asking them to keep testing for two months is hard. Meanwhile iPhone users have had the app since August. This round: 7 versions, 1.34.9 to 1.38.1. The wait has stalled our plans: Madeira Ativa passed this step and grows; BullDozer cannot yet.
```

---

## Where the numbers come from
- **20 requests, 18 fixed; 13 this round, 11 fixed the same or next day:** feedback log R6–R18 (R8 20→21 Oct, R9–R13 same day, R14 28→29 Oct, R15–R18 2 Nov same day). Open: R6, R7.
- **7 versions this round:** pubspec 1.34.9, 1.35.0, 1.36.0, 1.37.0, 1.37.1, 1.38.0, 1.38.1.
- **Android builds:** AABs 68, 69, 70, 72, 73, 75, 76, 77 built (71 and 74 iOS only); 75 never uploaded, 76 uploaded and discarded before review, 77 sent.
- **514 data files** inside the app: `scripts/bake_offline_data.py`, 2 Nov.
- **17 feeds:** bot `src/ai_news.js` — 6 news, 6 long-read, 2 extra image/video, 2 Karpathy, Hugging Face papers.
- **273 indicators, 232 countries:** catalogue and country index, 2 Nov.
- **App Store:** 1.28.0, 1.29, 1.34.8 Ready for Sale (App Store Connect API, 2 Nov). 1.35–1.38 are in TestFlight, not yet released there.
- **Closed testing since September, three rounds:** feedback log (period from 15 Sep; this round from 8 Oct).
- **Re-parsed every Monday:** GitHub Actions "Update data". Publishing to the site is still by hand.
