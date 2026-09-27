# Tester feedback log

Raw comments from closed-test testers, with what was done about each. Feeds
the production-access form ("Summarize the feedback you received" / "What
changes did you make"). Keep entries factual; the form must not claim
feedback that was never given.

## 2026-09-15 — "Where did the new data appear? Which sections do I look in?"

Asked after fourteen mortality series went live (WHO GHO + Global Health
Estimates 2021). The data was reachable in five places from the moment it
shipped — Macro › Health, every country profile (Poland: 15 mortality rows),
the Explore picker, Cmd+K search, and the Telegram bot — but nothing on the
site *announced* an addition. A user who does not already know the catalogue
has no way to notice it grew.

**Product gap:** no "recently added" surface. New datasets land silently.

**Candidate fix:** a "New this month" strip on the home page and on Macro /
Polls, driven by `parsedAt` on each dataset — no editorial work, it falls out of
the data. Possibly a `NEW` marker on the dataset card for 30 days.

**Status:** fixed, on both surfaces.
- App 1.31.0+55 (closed track): a "NEW SINCE YOUR LAST VISIT" strip and NEW
  badges, measured against what the device last saw.
- Site, 2026-09-25: a "datasets added this month" section on the home page and
  New badges in Macro and Polls. Arrival dates come from git history, not from
  parsedAt — parsedAt is the last re-parse, and it would have flagged 51
  datasets as new where 14 were.

**For the form:** this is presentation feedback, not a defect — consistent
with the summary already written ("clearer labels … not defects").

## 2026-09-27 — "Why is there no Ask AI? Type a country, see what you have on it and a short summary"

A tester asked for a way to type a country's name and get back what the app
holds on it, with a short summary.

**What it points at:** the app can answer "what is Kazakhstan's GDP" but not
"what is there to know about Kazakhstan". A country profile lists 150+ rows
with no way in for someone who does not already know what to look for.

**Status:** shipped in 1.33.0 (57), 27 September — an "Ask AI" tab after
Home, marked "in development". Type a country: what we hold on it (indicators
by topic, years covered) and up to six lines on where it stands out in the
world, each a published value with year, rank and source, selected by the site
from its own data. No model writes it yet, so nothing on the screen can be
invented. Building it also caught a labelling error visible on every page:
child mortality was shown "per 1,000" while the values are percentages —
Nigeria's 11.6% read as 11.6 per 1,000, ten times too low. Fixed.

---

## All tester requests, 11–27 September

Testers wrote to Kirill and he relayed each message as a task; they are
listed here in the order they arrived, with what shipped. Every one was about
content or presentation — none reported a fault.

| # | Date | Request, in substance | What shipped |
|---|------|------------------------|--------------|
| 1 | 11 Sep | Pointed at deathboard.com, a site of causes of death by country: can we have this? | 14 WHO mortality series — 3 from the GHO, 11 causes of death from Global Health Estimates 2021, 185 countries — and the story "What the world dies of" (25 Sep). Built from WHO's own files, not the other site. |
| 2 | 15 Sep | Alexey: where did the new data appear, which section? | "Added this month" section and NEW badges on the site (23 Sep); a "new" strip in the app (builds 55–56). |
| 3 | 15 Sep | Which open survey databases are we still missing? | CSES (4 series, then Module 6 to 2024), Afrobarometer 3 → 18 series, IEA TIMSS / PIRLS / ICCS / ICILS (8 series) — 25 Sep. LAPOP licence accepted, data being processed. |
| 4 | 27 Sep | Why is there no Ask AI — type a country, get what you have and a summary? | Ask AI tab, builds 57–58. |
| 5 | 27 Sep | The menu and the buttons at top right exist only on Home. | On every tab, build 58. |

Five requests, five answered; one of them (#3) is partly in progress —
LAPOP's AmericasBarometer is downloaded under its licence and being processed.
