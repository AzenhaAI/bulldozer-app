# Closed testing — tester feedback log

BullDozer Stats · `ai.azenha.bulldozer` · closed testing track

Kept for the Google Play closed-testing requirement, in the same form as Madeira
Ativa's log: one section per tester, their words, what was done, with dates and
build numbers. Feedback arrives by direct message to the developer and is
relayed as tasks; quotes are translated from Russian where needed.

**Rule for this file:** nothing goes in that a tester did not say. Where a name,
device or exact wording was not recorded, the field says so and is filled in
when the tester confirms it — never reconstructed.

Started 2026-10-08, third closed-test round. Earlier entries are carried over
from `PLAY-tester-feedback.md` (11–27 September), which keeps the full notes.

---

## Tester 1 — Alexey

**Who:** _to confirm — role, device (Android model), how long using the app._
**Period:** 15 September 2026 onward.
**Builds seen:** _to confirm — which build was installed when he wrote._

| # | Date | What he said | Status |
|---|------|--------------|--------|
| A1 | 15 Sep | "Where did the new data appear? Which sections do I look in?" — asked after fourteen mortality series went live. | **Fixed, on both surfaces.** The data was reachable from day one (Macro › Health, every country profile, Explore, search, the bot), but nothing announced an addition. App 1.31.0 (55): a "new since your last visit" strip and NEW badges. Site, 23–25 Sep: "datasets added this month" on the home page, NEW badges in Macro and Polls. Arrival dates come from git history, not the last re-parse — the re-parse date would have flagged 51 datasets as new where 14 were. |

## Requests from testers not yet named in this log

Relayed by the developer between 11 and 27 September; who sent each is not
recorded here yet. Each row moves into that tester's own section once they
confirm it was theirs.

| # | Date | Request, in substance | Status |
|---|------|------------------------|--------|
| R1 | 11 Sep | Pointed at deathboard.com, causes of death by country: "can we have this?" | **Fixed, 25 Sep.** 14 WHO mortality series — 3 from the GHO, 11 causes of death from Global Health Estimates 2021, 185 countries — and the story "What the world dies of". Built from WHO's own files, not from the other site. |
| R2 | 15 Sep | Which open survey databases are still missing? | **Fixed, 25–28 Sep.** CSES (4 series), Afrobarometer 3 → 18 series, IEA TIMSS / PIRLS / ICCS / ICILS (8 series); LAPOP AmericasBarometer 2004–2026 (11 series, 28 countries) on 28 Sep. Remaining ones need an account or a written application and are logged in the sources backlog. No app update is needed for new data: the app reads the live catalogue. |
| R3 | 27 Sep | "Why is there no Ask AI? Type a country, see what you have on it and a short summary." | **Fixed, in three steps.** 1.33.0 (57): an Ask AI tab after Home — what the app holds on a country and where it stands out, every line a published figure with year, rank and source. 1.34.0 (59): an answer in words, written by a model from those figures only; every number in it is checked against our data before it is shown, and an answer with a number we do not hold is dropped. 1.34.2 (61): labelled Beta, and every answer says AI can be wrong and the figures below are the source. |
| R4 | 27 Sep | The menu and the buttons at top right exist only on Home. | **Fixed, 1.33.1 (58).** Theme, search and menu on every tab. Doing it found a real defect: the menu addressed tabs by position, so after Ask AI was inserted "Statistics" opened Ask AI and Edu could not be reached at all. One list now drives both the bar and the menu. |
| R5 | 27 Sep | Ask AI should accept a country code like "kz", as the country search does. _Source to confirm: a tester, or noticed by the developer — drop the row if the latter._ | **Fixed, 1.34.0 (59).** Two- and three-letter codes in Ask AI; 1.34.1 (60) also takes a country and a question on one line ("kz standard of living"). |

## Found while acting on these reports

Not reported by testers, found because their requests were followed through.
Same kind of defect each time: the product saying something its data does not.

- **Child mortality was shown "per 1,000" while the values are percentages** —
  Nigeria's 11.6% read as 11.6 per 1,000, ten times too low. Found while
  building Ask AI (R3). Fixed on every page.
- **Ask AI answered English questions in German or Spanish** (28 Sep). The
  reply language is now set by the server from the question, as it already
  was for Madeira Ativa and AlfaCat, which had the same fault.
- **Correct answers were thrown away**: the figures say "per 100k", the answer
  said "per 100,000", and the number check took 100,000 for an invented figure,
  so some answers fell back to a weaker model or to none (28 Sep). Fixed; an
  invented figure is still caught.
- **A survey series was mislabelled**: "Internet at home" from LAPOP was in
  fact broadband at home. Renamed within hours of publication (28 Sep).

---

## Summary

| | Count |
|---|---|
| Testers who wrote, named in this log | 1 (more to be confirmed) |
| Requests and reports received, 11–27 Sep | 6 (5 confirmed from testers, R5 to confirm) |
| Fixed and shipped | 6 |
| Pending / deferred | 0 |
| Defects found while acting on them | 4, all fixed |
| Builds shipped to the closed track in response | _to confirm against Play Console — see note_ |

**Note on builds.** The code is at 1.34.2 (61). Which builds actually reached
the closed track has to be read from Play Console, not from this repo; the
answers in the production form must name only builds testers could install.
