# Production access — answers, second pass (after the 14-day window)

BullDozer Stats · `ai.azenha.bulldozer` · built on what got Madeira Ativa
through: every number checkable, nothing rounded up. Numbers below were read
on 2026-09-25 from Play Console (installed audience), git history and the
live site.

**Before pasting — confirm the four items marked ⚠.** They are the ones only
you can see: they are facts about the Play track and the testers' messages,
not about the code.

---

## How did you recruit users for your closed test?  *(261 characters)*

```
The same circle that tests our other apps: friends and acquaintances, asked one by one over Telegram and WhatsApp, no paid provider. Each gave the Google account on their phone; we added it to the track and sent the opt-in link with install steps. 13 installed.
```
⚠ Same circle as Ativa and the other apps (PLAY-STEPS.md suggested it); change
if BullDozer's testers came from somewhere else.

**How easy was it to recruit testers?** — Moderate. The circle already existed
from the first app, so the work was collecting Google account addresses and
walking people through the opt-in, not finding them.

---

## Describe the engagement you received from testers  *(271 characters)*

```
13 installed and used it on their own phones. Questions came back by direct message and were about presentation, not faults: what a metric means, which way a rank runs, where 14 new series had gone. Each answer shipped in a build or in the live data. No crashes reported.
```
⚠ "No crashes reported" — check Android vitals → Crashes and ANRs for the
test window before sending. If anything is there, drop the sentence.

---

## Summary of the feedback, and how you collected it  *(272 characters)*

```
By direct message, in testers' words. With 200+ indicators the questions were about reading, not bugs: labels, what a metric measures, whether #1 is best or just highest, and — after 14 new series landed — where they were. Each was answered in a build or on the live data.
```

---

## What changed as a result of testing  *(265 characters)*

```
Three builds in the test (54-56). New data now announced: an "added this month" strip and NEW badges. Ranks say highest/lowest, not best/worst. Chart export and on-screen sources. Two duplicate series and six missing populations fixed. Offline catalogue 154 to 219.
```
⚠ "Three builds (54–56)": 54 went up around 21 August; 55 was built on
15 September — confirm it reached the closed track; 56 is today's. If 55
never went up, write "Two builds (54 and 56)".

---

## About the app

**Who is the intended audience?**  *(242 characters)*

```
Students, analysts, journalists and anyone who needs to check a figure about a country and see where it stands in the world: GDP, life expectancy, democracy, school results and 220 other indicators for 232 countries. Free, no account, no ads.
```

**How does your app provide value?**  *(264 characters)*

```
One place for public country statistics otherwise spread across the IMF, World Bank, WHO, IEA, Afrobarometer and others. Every figure shows its source and year and is checked against the publisher. Profiles, rankings and comparisons; what was loaded works offline.
```

**Expected installs** — say what is true: a niche reference tool, no paid
acquisition. "Hundreds in the first months; growth through the website and the
Telegram bot that already exist."

---

## Production readiness  *(265 characters)*

```
Ready. 13 testers installed; three builds shipped during the test, each closing what testers raised. No crashes reported. The same app is live on the App Store after review. It collects no data and needs no account; listing, screenshots and privacy policy are live.
```

---

## The evidence behind the answers

### During the test (from 21 August)

| | |
|---|---|
| Testers installed (Play Console, 25 Sep) | **13** |
| App builds in the closed track | 54 (21 Aug) · 55 (15 Sep) ⚠ · 56 (25 Sep) |
| App code changed | 323 lines added, 158 removed, in `lib/` |
| Datasets the app reads | 186 → **227** (+41), all live without a new build |
| Site and data commits | 36 |

### What testers raised, and what was done

| Raised | Done | Where |
|---|---|---|
| Where did the new data go? (Alexey, after 14 WHO series landed on 11 Sep) | "Added this month" strip and NEW badges; the site got the same section | app 55/56, site 25 Sep |
| What a metric means; which way a rank runs | Ranks read "highest / lowest", never best/worst; a note says #1 on child mortality is the worst outcome | site and bot, early Sep |
| Labels and explanations on charts | Source shown on every chart on screen, not only in the export; copy-link and PNG on every chart (196 pages) | site, Sep |

⚠ This table holds what is written down. If testers sent more — screenshots,
messages in Telegram — send them over and they go in here with dates, the
way Ativa's log did (32 findings, 18 fixed). That log is what turned Ativa's
refusal into approval: engagement shown, not described.

### Found by us while answering them

- Cyprus had two life-expectancy series; Poland showed life expectancy twice —
  duplicate datasets removed.
- Six countries had no population figure — fixed.
- The offline catalogue a first launch shows had stopped at 154 datasets
  against 219 live — regenerated in build 56.
- Every new source checked against its publisher before shipping: TIMSS 2023
  matches IEA's table for all 54 countries at grade 4, PIRLS 2021 for 42 of 42.
