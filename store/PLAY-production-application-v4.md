# Production access — answers, final (27 September)

BullDozer Stats · `ai.azenha.bulldozer`. Written the way Madeira Ativa's
passing application was: every number checkable, nothing rounded up, nothing
a tester did not ask. The five requests are in `PLAY-tester-feedback.md` with
dates and what shipped.

## Two checks before you paste
1. **Builds in the closed track.** The answers say "54 to 58". If 55–57 never
   went up, write what is true. Upload **58**, not 57 (57 has the menu bug).
2. **Android vitals → Crashes and ANRs.** The answers no longer claim "no
   crashes"; if vitals are clean you may add it back.

---

## How did you recruit users for your closed test?  *(261 characters)*
```
The same circle that tests our other apps: friends and acquaintances, asked one by one over Telegram and WhatsApp, no paid provider. Each gave the Google account on their phone; we added it to the track and sent the opt-in link with install steps. 13 installed.
```

**How easy was it?** — Moderate. The circle existed from the first app; the
work was collecting Google account addresses and walking people through the
opt-in.

## Describe the engagement you received from testers  *(280 characters)*
```
13 installed on their own phones; all 13 still have it five weeks in. In two weeks they wrote in with five requests, and all five are live: causes-of-death data, a way to see new datasets, more open surveys, an Ask AI tab, the menu on every tab. Release notes name screens to try.
```

## Summary of the feedback, and how you collected it  *(264 characters)*
```
Direct messages in testers' own words, logged with dates. Five requests: add causes of death (they pointed at another site), show where new data lands, add more open surveys, an Ask AI summary per country, the menu on every tab. Content and presentation, not bugs.
```

## What changed as a result of testing  *(253 characters)*
```
Builds 54 to 58. Ask AI tab; "Added this month" with NEW badges; menu and search on every tab. Data 186 to 227 series: WHO causes of death, TIMSS, PIRLS, CSES, Afrobarometer, checked against the publishers. Fixed child mortality shown ten times too low.
```

## Who is the intended audience?  *(242 characters)*
```
Students, analysts, journalists and anyone who needs to check a figure about a country and see where it stands in the world: GDP, life expectancy, democracy, school results and 220 other indicators for 232 countries. Free, no account, no ads.
```

## How does your app provide value?  *(267 characters)*
```
One place for public country statistics otherwise spread across the IMF, World Bank, WHO, IEA, Afrobarometer and others. Every figure shows its source and year and is checked against the publisher. Profiles, rankings, a country summary; what was loaded works offline.
```

**Expected installs** — "Hundreds in the first months; growth through the
website and the Telegram bot that already exist."

## Production readiness  *(251 characters)*
```
Ready. 13 testers installed; builds 54 to 58 shipped during the test, and all five tester requests are live. The same app is on the App Store after review. It collects no data and needs no account; the listing, screenshots and privacy policy are live.
```

## Only if this is a second application — what did you do differently?  *(275 characters)*
```
Testers asked and the next build answered: five requests in two weeks, all five live — causes of death, badges for new data, more surveys, Ask AI, the menu on every tab. Five builds, not one; data grew from 186 to 227 series, the 41 new ones checked against their publishers.
```

---

## The evidence

| # | Date | Tester request | Shipped |
|---|------|----------------|---------|
| 1 | 11 Sep | Causes of death by country, like deathboard.com | 14 WHO series + story "What the world dies of" |
| 2 | 15 Sep | Where did the new data appear? (Alexey) | "Added this month" + NEW badges (site); strip in app 55–56 |
| 3 | 15 Sep | Which open surveys are we missing? | CSES + Module 6, Afrobarometer 3→18, TIMSS/PIRLS/ICCS/ICILS; LAPOP in progress |
| 4 | 27 Sep | Why no Ask AI — type a country, get a summary? | Ask AI tab, 57–58 |
| 5 | 27 Sep | Menu and top-right buttons only on Home | Every tab, 58 |

Found by us while answering them: child mortality labelled "per 1,000" while
the values are percentages (ten times too low, fixed); menu opening the wrong
tab in 57 (fixed in 58); offline catalogue stuck at 154 of 219 datasets
(regenerated in 56).

| | |
|---|---|
| Testers installed | 13 (Play Console) |
| Tester requests | 5, all live |
| Builds during the test | 54 → 58 |
| Series the app reads | 186 → 227; TIMSS matches IEA for 54/54 countries, PIRLS 42/42 |
