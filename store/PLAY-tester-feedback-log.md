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

## Tester 2 — Alexander

**Who:** _to confirm — device._ Writes in Russian, sends screenshots with the
problem circled in red, numbers his points. Opened with "Bulldozer. I'll be
pouring out thoughts bit by bit."
**Period:** 2 October 2026, on an app build without the Ask AI tab (1.32 or
earlier — _to confirm_).
**Volume:** 2 observations so far, both on the home screen globe, both with
screenshots.

| # | Date | What he reported (translated) | Status |
|---|------|-------------------------------|--------|
| X1 | 2 Oct | "Not a bug as such, but the globe works like an aircraft yoke reversed left-right — it may put people off. It is not intuitive, given that up-down works without the reverse." | **Fixed, 1.34.3 (62), and he was exactly right.** Dragging right moved the view centre east, so the surface slid left — against the finger — while the vertical drag followed it. One sign. The idle spin was turned to run west to east, as the Earth does. |
| X2 | 2 Oct | "Also not a bug, but maybe look at how the map is laid onto the 3D sphere. You can see artefacts of the spherical model on the continents. Maybe increase the sphere's faceting to smooth it." (Indonesia and Australia circled, at the edge of the globe) | **Fixed, 1.34.3 (62).** His diagnosis was close: coastlines were drawn as straight lines between sparse points, and points on the far side of the globe were dropped, so a country cut by the horizon was closed with a chord across the disk — the slivers he circled. Edges are now split into ~1° steps and far-side points are pinned to the rim, so a country ends along the globe's edge. Verified on an Android emulator with Indonesia and Australia at the rim. |

## Requests from testers not yet named in this log

Relayed by the developer between 11 September and 21 October; who sent each is
not recorded here yet. Each row moves into that tester's own section once they
confirm it was theirs.

| # | Date | Request, in substance | Status |
|---|------|------------------------|--------|
| R1 | 11 Sep | Pointed at deathboard.com, causes of death by country: "can we have this?" | **Fixed, 25 Sep.** 14 WHO mortality series — 3 from the GHO, 11 causes of death from Global Health Estimates 2021, 185 countries — and the story "What the world dies of". Built from WHO's own files, not from the other site. |
| R2 | 15 Sep | Which open survey databases are still missing? | **Fixed, 25–28 Sep.** CSES (4 series), Afrobarometer 3 → 18 series, IEA TIMSS / PIRLS / ICCS / ICILS (8 series); LAPOP AmericasBarometer 2004–2026 (11 series, 28 countries) on 28 Sep. Remaining ones need an account or a written application and are logged in the sources backlog. No app update is needed for new data: the app reads the live catalogue. |
| R3 | 27 Sep | "Why is there no Ask AI? Type a country, see what you have on it and a short summary." | **Fixed, in three steps.** 1.33.0 (57): an Ask AI tab after Home — what the app holds on a country and where it stands out, every line a published figure with year, rank and source. 1.34.0 (59): an answer in words, written by a model from those figures only; every number in it is checked against our data before it is shown, and an answer with a number we do not hold is dropped. 1.34.2 (61): labelled Beta, and every answer says AI can be wrong and the figures below are the source. |
| R4 | 27 Sep | The menu and the buttons at top right exist only on Home. | **Fixed, 1.33.1 (58).** Theme, search and menu on every tab. Doing it found a real defect: the menu addressed tabs by position, so after Ask AI was inserted "Statistics" opened Ask AI and Edu could not be reached at all. One list now drives both the bar and the menu. |
| R5 | 27 Sep | Ask AI should accept a country code like "kz", as the country search does. _Source to confirm: a tester, or noticed by the developer — drop the row if the latter._ | **Fixed, 1.34.0 (59).** Two- and three-letter codes in Ask AI; 1.34.1 (60) also takes a country and a question on one line ("kz standard of living"). |
| R6 | 20 Oct | "The AI part of the app needs work" — relayed in substance; which tester, and their exact words, _to confirm_. | **Open.** Taken as direction for the fourth test round. Candidate answers written up 21 Oct: figures the answer rests on shown as chips under it, comparison of two countries, trend questions, streaming. Which ship first is decided with the testers. |
| R7 | 21 Oct | A place to try language models inside the app, "like Ollama / OpenCode / OpenRouter": choose from the models available, try them free, add your own. Today that means Telegram, Python or similar, which is inconvenient. Several testers; names _to confirm_. | **Open, planned.** Fourth round: a model picker in Ask AI — Claude, open models on Workers AI, a user's own Ollama by local address, a user's own provider key — on the same checked country questions, so every number is still verified. Free-form chat with arbitrary models is a different product (content rating, reporting duty) and is kept out of BullDozer. |
| R8 | 20 Oct | On a weak 5G signal the app showed "190+ countries" on Home, a spinner under Data stories that never ended, and on a dataset page a raw error ("ClientException with SocketException: Failed host lookup: 'azenha.ai' … errno = 8"). Screenshots, 21:05–21:06. Tester _to confirm_. | **Fixed, 1.34.9 (68), 21 Oct.** The cause was the phone's DNS, not the service (no Cloudflare incident at that hour; the request never reached us). The app's fault was how it showed it. Now: every page says "No connection. Check the internet and try again." with a Retry button — datasets, stories, countries, brands, cities, the quiz and the Home feed; the country count comes from the cached manifest, never a literal. Verified on a simulator pointed at a dead host. |
| R9 | 21 Oct | "Can I download the data and work with it offline, as an archive?" Tester _to confirm_. | **Fixed, 1.34.9 (68), 21 Oct.** Menu → "Download all data": fetches the whole catalogue — 273 indicators, 232 country briefs, 9 index files, 514 files, about 25 MB — into the cache every page already reads when offline; progress bar, Cancel keeps what was fetched, the menu row then shows the date of the copy. Wikipedia summaries and images stay online-only. **Extended, 1.35.0 (69), 22 Oct:** a tester's iPhone with mobile data off for the app still showed "No connection" on Home — so the whole catalogue now ships inside the app (2 MB compressed, data as of 11 Oct) and is unpacked on the first failed fetch; with no connection and an empty cache every indicator and country opens. Verified on a simulator with the cache wiped and the network unreachable: 514 files unpacked, Home and the Brazil profile complete. |
| R10 | 23 Oct | Showed an "Amazing Maps" picture ("Will you receive food as a guest at someone's house?", Europe in four colour classes) and asked why BullDozer has no maps like that, and whether Edu could have a generator that makes such maps on request — including from users' own data. Testers, names _to confirm_. | **Fixed, 1.36.0 (70), 23 Oct.** Edu → "Make your own" → Map maker: any of our 273 indicators; World, Europe, Africa, Asia, Americas or Latin America; 3–5 classes of about equal size, renamed in words; red–blue, amber or viridis, reversible; light or dark; square, portrait or story, exported at 1080 px with the source and years printed on it. Own data (paste a table) is the next step. The example map names no source, so it is not reproduced. |

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
| Testers who wrote, named in this log | 2 (more to be confirmed) |
| Requests and reports received, 11 Sep – 23 Oct | 13 (12 from testers, R5 to confirm) |
| Fixed and shipped | 11 (X1–X2 in 1.34.3, 11 Oct; R8–R9 in 1.34.9–1.35.0, 21–22 Oct; R10 in 1.36.0, 23 Oct) |
| Open, for the fourth round | 2 (R6, R7 — AI block) |
| Defects found while acting on them | 4, all fixed |
| Builds shipped to the closed track in response | _to confirm against Play Console — see note_ |

**Note on builds.** The code is at 1.34.9 (68); 67 is in the closed track since 12 Oct, 68 built 21 Oct. Which builds actually reached
the closed track has to be read from Play Console, not from this repo; the
answers in the production form must name only builds testers could install.
