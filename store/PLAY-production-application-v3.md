# Production access — answers, final pass (27 September)

BullDozer Stats · `ai.azenha.bulldozer`. Written the way Madeira Ativa's
passing application was: every number checkable, nothing rounded up, nothing
a tester did not say. Sources: Play Console (13 installed, 25 Sep), git history
of the app, the site and the bot, and `PLAY-tester-feedback.md`.

## Before you paste — three checks only you can make

1. **Which builds reached the closed track.** The answers say "54 to 58".
   If 55, 56 or 57 never went up, write "54 and 58" (or whatever is true).
   Upload **58**, not 57: 57 has the menu bug.
2. **Android vitals → Crashes and ANRs** for the test window. If anything is
   there, delete "No crash was reported." from the feedback answer.
3. **Other testers' messages.** Only two requests are written down (Alexey on
   new data; a tester on Ask AI) plus your own summary. If the other testers
   wrote — Telegram, WhatsApp, anything — forward it; each goes into the log
   with a date and the answers get stronger. Nothing below claims more than
   those two.

---

## How did you recruit users for your closed test?  *(261)*
```
The same circle that tests our other apps: friends and acquaintances, asked one by one over Telegram and WhatsApp, no paid provider. Each gave the Google account on their phone; we added it to the track and sent the opt-in link with install steps. 13 installed.
```
**How easy was it to recruit testers?** — Moderate. The circle existed from the
first app; the work was collecting Google account addresses and walking people
through the opt-in.

## Describe the engagement you received from testers  *(272)*
```
13 installed on their own phones, and all 13 still have it five weeks in. Requests came by direct message and became features: one tester asked where new data had gone, another for a way to type a country and get a summary. Both shipped. Release notes name screens to try.
```

## Summary of the feedback, and how you collected it  *(261)*
```
Direct messages, in testers' words. With 220 indicators the questions were about reading, not bugs: what a metric measures, whether #1 is best or only highest, where 14 new series went, and a wish to ask about a country and get a summary. No crash was reported.
```

## What changed as a result of testing  *(260)*
```
Builds 54 to 58. New: an Ask AI tab giving a country's standout figures, each with year, rank and source; "Added this month" with NEW badges; menu and search on every tab. Ranks say highest or lowest. Fixed a unit that showed child mortality ten times too low.
```

## Who is the intended audience?  *(242)*
```
Students, analysts, journalists and anyone who needs to check a figure about a country and see where it stands in the world: GDP, life expectancy, democracy, school results and 220 other indicators for 232 countries. Free, no account, no ads.
```

## How does your app provide value?  *(267)*
```
One place for public country statistics otherwise spread across the IMF, World Bank, WHO, IEA, Afrobarometer and others. Every figure shows its source and year and is checked against the publisher. Profiles, rankings, a country summary; what was loaded works offline.
```

**Expected installs** — a niche reference tool, no paid acquisition: "hundreds
in the first months; growth through the website and the Telegram bot that
already exist."

## Production readiness  *(267)*
```
Ready. 13 testers installed; builds 54 to 58 shipped during the test, each answering what testers raised, and both feature requests are live. The same app is on the App Store after review. It collects no data and needs no account; listing and privacy policy are live.
```

## Only if this is a second application — "What did you do differently?"  *(276)*
```
Testers asked for things and got them in the next build: Ask AI and "Added this month" both came from their messages. Release notes now name screens to try. Five builds in the window, not one; data grew from 186 to 227 series, the 41 new ones checked against their publishers.
```

---

## The evidence

### Tester requests and what shipped

| Date | Request | Shipped |
|---|---|---|
| mid-Sep | Alexey: where did the new data go? (after 14 WHO series on 11 Sep) | "Added this month" strip + NEW badges — app 55/56; same section on the site |
| 27 Sep | A tester: why no Ask AI — type a country, get what you have and a summary | Ask AI tab — app 57/58; every line a published value with year, rank, source |
| Sep (your summary) | Labels, what a metric means, which way a rank runs | Ranks read highest/lowest, never best/worst; source on every chart; export on every chart |

### Found by us during the test

| | |
|---|---|
| Child mortality labelled "per 1,000" while the values are percentages — Nigeria read ten times too low | fixed in data and parser |
| Menu and search only on Home | on every tab, build 58 |
| Menu opened the wrong tab after a tab was inserted (build 57) | fixed in 58; tabs and menu now read one list |
| Offline catalogue stuck at 154 of 219 datasets | regenerated, build 56 |
| Cyprus with two life expectancies; six countries without population; duplicate series | fixed on the live data |

### In numbers

| | |
|---|---|
| Testers installed | 13 (Play Console) |
| Builds during the test | 54 → 58 (confirm which reached the track) |
| Datasets the app reads | 186 → 227; the 41 new ones checked against their publishers (TIMSS 54/54, PIRLS 42/42 countries match IEA's tables) |
| Tester requests shipped | 2 of 2 |
