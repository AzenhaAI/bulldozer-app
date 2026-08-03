# BullDozer — App Store Connect copy (v1.28.0+44)

English metadata for the first App Store release. Character counts verified
against Apple limits with `len()` on the exact strings.

| Field | Limit | Count |
|---|---|---|
| App name | 30 | **27** |
| Subtitle | 30 | **29** |
| Keywords | 100 | **97** |
| Promotional text | 170 | **166** |
| Description | 4000 | **~1990** |

## App name

```
BullDozer: World in Numbers
```

## Subtitle

```
Country stats, maps & quizzes
```

## Keywords

No spaces after commas; no term repeats a word from the name or subtitle
(name+subtitle words are already indexed).

```
statistics,geography,economy,gdp,data,atlas,rankings,charts,compare,facts,trivia,indicators,polls
```

## Promotional text

```
Explore the world through data: rank 150+ indicators, compare up to 5 countries side by side, browse interactive maps and test yourself in the Guess the Country quiz.
```

## Description

```
BullDozer turns the world into numbers you can actually explore. Compare countries across 150+ indicators covering the economy, society, business and the environment — with fast charts, world maps, country profiles and a data quiz. Free, with no account, no ads and no tracking.

CHARTS & RANKINGS
Browse 150+ indicators, search them, filter by topic and rank every country on any of them. Switch periods to see how the ranking changes, and tap any country bar to open its trend over time.

COUNTRY PROFILES
Pick a country from a searchable list with flags and get the full picture: a map zoomed to the country, headline macro figures, a short encyclopedic summary, and every available indicator grouped into Statistics and Surveys.

COMPARE
Put up to 5 countries side by side on any indicator and see who leads, who lags and how the gap has changed.

EXPLORE
Plot any indicator against any other across all countries in a scatter view — a quick way to spot how wealth, health, demography and values relate.

WORLD MAPS
Every dataset has a world choropleth coloured by the data. Tap a country on the map to see its trend line.

DATA STORIES
A feed of featured stories with live mini charts and quick facts — a fresh angle on the numbers every time you open the app.

QUIZ
"Guess the Country": data facts are your hints, and the fewer hints you use, the higher your score. A painless way to build real data literacy — for students, teachers and anyone who loves world facts.

MADE FOR EXPLORING
• Fast and lightweight, works offline once data is loaded
• Light and dark themes
• Clear, readable charts on every screen

PRIVACY FIRST
No account, no sign-up, no ads, no tracking. The app simply shows you the data.

ABOUT THE DATA
Figures come from public datasets and international surveys, credited on screen, with country summaries from Wikipedia (CC BY-SA), served through the open BullDozer feed at shpara.com/bulldozer.
```

## What's New (1.28.0 — first release)

```
Welcome to BullDozer — our first release on the App Store!

• 150+ indicators with rankings, trends and a period switcher
• Country profiles with maps, key figures and summaries
• Side-by-side comparison of up to 5 countries
• A world choropleth map for every dataset
• A scatter view to explore how indicators relate
• Data stories with live mini charts
• The "Guess the Country" quiz

Free, no account, no ads, no tracking.
```

# App Information

- **Category**: Primary **Education**, Secondary **Reference**
- **Content Rights**: **Yes** — third-party content (public datasets, Wikipedia
  summaries CC BY-SA, Wikimedia Commons images, Kantar BrandZ / Forbes brand
  values; all credited on screen)
- **Age Rating questionnaire**: everything None/No **except** Alcohol, Tobacco,
  or Drug Use or References → **Infrequent/Mild** (WHO alcohol and tobacco
  statistics datasets). If the questionnaire asks about self-harm themes, answer
  the mildest reference tier honestly (WHO suicide-rate statistics, purely
  numerical). Expected result: **13+**.
- **Copyright**: `2026 Kirill Shpara`
- **Price**: Free · **Release**: Automatically release this version

# App Privacy

**Data Not Collected.** Verified by audit: every network call is a GET to
`shpara.com/bulldozer/data/*`, the Wikipedia REST summary (country name only)
or Wikimedia Commons images; favourites, quiz progress and theme stay on the
device; no analytics or ads SDK exists in the dependency tree.

- Privacy Policy URL: `https://shpara.com/bulldozer/privacy/`
- Support URL: `https://shpara.com/bulldozer/support/`

# Notes for Reviewer

```
BullDozer: World in Numbers is a fully native Flutter app — there is no webview anywhere in the binary. Every chart, the flat world choropleth and the spinning globe, the values scatter, the animated bubble player, country profiles, data stories and the quiz are rendered natively. There is no account, no login, no in-app purchase, no advertising and no user-generated content; no demo credentials are needed — every screen is reachable from a cold launch.

DATA AND LICENSING
Figures come from public statistical datasets (WHO, World Bank, Eurostat, international surveys), served through our own open feed at shpara.com/bulldozer and credited on the screens where they appear. Country summaries are fetched from the Wikipedia REST API and labelled "Wikipedia · CC BY-SA" with a link to the article. Brand values on the business screens are credited to Kantar BrandZ / Forbes; brand logos come from Wikimedia Commons and are used for identification only. Coat-of-arms images likewise come from Wikimedia Commons.

AGE RATING
The catalog includes WHO public-health statistics such as alcohol consumption, tobacco use and suicide rates — numerical, educational data with no depiction or promotion; the questionnaire is answered accordingly.

PRIVACY
The app collects no data. All requests are anonymous GETs for public JSON/CSV; favourites, quiz progress and the theme choice are stored on the device only. Privacy policy: https://shpara.com/bulldozer/privacy/ — also linked from the app's side menu.

TESTING NOTE
First launch needs a connection to load the catalog; data is then cached for offline use. Notifications are only requested when the user taps the bell on a data release, never at launch.
```
