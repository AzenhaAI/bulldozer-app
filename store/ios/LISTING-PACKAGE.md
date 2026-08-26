# App Store listing package — BullDozer: World in Numbers

Generated from the app's own source, then read back by an adversarial
reviewer. Fields are meant to be pasted into App Store Connect as-is;
character counts are the ones Apple enforces.

## Positioning

**One line.** A free atlas of world statistics — 180 indicators and 232 country profiles built from public data, with rankings, world maps, a spinning globe and a data quiz.

**Audience.** Curious generalists and news readers who want the real number behind a headline; students and teachers in geography, economics and social science; analysts, journalists and travellers who need a credible country figure on a phone without opening a spreadsheet or signing into a dashboard.

**Why this over the alternative.** Everything is free and account-free, every figure names its public source on screen, and the whole catalogue is one continuous surface: a ranking becomes a world map becomes a country profile becomes a quiz question about the same number. The alternatives are paywalled BI dashboards, single-source apps that show one agency's data, or country-trivia games with no real data underneath. Nothing here asks you to sign up, and nothing tracks you.

## Pricing

**Recommendation.** Ship it Free with no monetisation. It is the only option that requires no code change, no Paid Apps agreement and no banking or tax filing before submission, and it keeps the review notes and the "Data Not Collected" declaration exactly as written. An unknown developer with zero installs needs downloads and reviews far more than it needs the roughly nothing that a first-year tip jar or a $2.99 price would earn. Revisit after about six months of real install data: if there is an audience, add the Option B supporter unlock that gates nothing. Do not consider the subscription unless the feed is genuinely being refreshed on a published schedule.

### A. Free, no monetisation (recommended) — Free

*Mechanics.* App Store Connect: Pricing and Availability -> Price Schedule = Free, all territories. Nothing else to configure. No Paid Apps agreement, no banking or tax forms, no StoreKit plugin, no purchase UI, no restore flow. App Privacy stays "Data Not Collected"; the review note line "no in-app purchase, no advertising" stays true. The binary that is already built is the binary you ship.

*Why.* Marginal cost per install is effectively zero — the data feed is static JSON on Cloudflare Pages, already paid for by the website. With no install base and an unfamiliar developer name, the first year is entirely about impressions, downloads and the first fifty ratings, all of which a price tag suppresses. Free also keeps the Education use case alive: a teacher can tell thirty students to install it without anyone needing a purchase approval.

*Risk.* No revenue, and no signal at all about willingness to pay. Adding monetisation later always needs a new build and a new review. If the app does find an audience, you will have given away the easiest moment to introduce a price.

### B. Free with an optional supporter unlock (non-consumable) — Free, plus a one-off $4.99 "BullDozer Supporter" non-consumable

*Mechanics.* ASC: sign the Paid Apps agreement, complete banking and tax details for Azenha AI (Portugal, non-trader), then create one non-consumable in-app purchase with a localized display name, description, a review screenshot and a review note. In the app: add a StoreKit plugin (none is present today — the dependency list has no IAP plugin), a small purchase screen, and a Restore Purchases button, which Apple requires and rejects builds for omitting. Decide what the unlock buys: the safe answer is nothing functional — a supporter badge and the removal of a single "support this app" row. If you insist on gating, gate only CSV export and share-as-image, never any data or chart. The review notes must stop saying "no in-app purchase", and the App Privacy questionnaire stays "Data Not Collected" (StoreKit purchases do not change that).

*Why.* Keeps free discovery completely intact while producing a real willingness-to-pay signal. A tip jar is also the honest shape for an app whose entire content is public data the developer did not create — you are charging for the assembly, not the numbers.

*Risk.* Tip-jar conversion is routinely under one percent of installs, so against a zero install base this earns close to nothing while adding StoreKit code, a restore path, tax paperwork and a fresh rejection surface. Gating CSV export or sharing would directly contradict the "the app simply shows you the data" line in the description and reliably attracts one-star reviews on a free-listed app.

### C. Paid up front — $2.99 one-off

*Mechanics.* ASC: Paid Apps agreement, banking and tax details, then set the tier in Price Schedule. Zero code changes and no IAP products. Be aware that iOS has no free trial for a paid non-subscription app, so the screenshots and the description are the entire purchase decision — which makes the shot list and the first screenshot far more load-bearing than under any other option.

*Why.* The simplest real monetisation: no StoreKit, no restore flow, no entitlement logic, and revenue on the very first download. It suits an app that is feature-complete rather than a work in progress, which this one is.

*Risk.* Discovery collapses. An unknown developer, a Reference/Education shelf crowded with free atlases, and no ratings means conversion from an already tiny impression count rounds to zero — a paid app with no marketing typically sells single-digit copies a month. It also kills the classroom and word-of-mouth channel, which is this app's most plausible growth path. Expect refund requests from buyers who assumed live market data; everything here is annual and periodic public statistics.

### D. Auto-renewable subscription — $1.99/month or $9.99/year with a 7-day free trial

*Mechanics.* ASC: Paid Apps agreement, banking and tax, a subscription group containing two auto-renewable products, an introductory offer configured per territory, localized metadata and a review screenshot for each. In the app: StoreKit 2, entitlement checking, restore, and a paywall that must display price, billing period and renewal terms and link to both a Terms of Use (EULA) and the privacy policy — Apple checks all of this. The App Store description must also carry the subscription terms.

*Why.* Only defensible if the app ships genuinely new datasets and stories on a schedule — the twelve entries in releases.json and the data-release reminder feature hint at that rhythm, so the story is at least tellable.

*Risk.* By far the highest rejection risk of the four. App Review scrutinises subscriptions on content the developer does not own, and "public data behind a recurring charge" is a recurring rejection under Guidelines 3.1.2 and 4.2. It also commits one solo developer to a permanent content obligation: any month the feed goes stale becomes churn, refund requests and public reviews saying so. Not sustainable for a first-time publisher.

## App Store Connect fields

### Name (30)  ·  27 chars

**Now:** BullDozer: World in Numbers

**Paste:**

```
BullDozer: World in Numbers
```

*Why.* No change. It reads as a title plus a plain-English descriptor, which is exactly what the App Store name field is for, and "World" and "Numbers" are already indexed so they never need to be repeated in Keywords.

### Subtitle (30)  ·  29 chars

**Now:** Country stats, maps & quizzes

**Paste:**

```
Country data, maps & rankings
```

*Why.* "Rankings" is what the app actually leads with on every dataset screen and is a much higher-intent search term than "quizzes"; "quiz" is cheaper to carry in Keywords than to spend a subtitle slot on. "Stats" is dropped because "statistics" belongs in Keywords where it is a stronger stem. Every word here is load-bearing and none is repeated in Name.

### Keywords (100)  ·  100 chars

**Now:** statistics,geography,economy,gdp,data,atlas,rankings,charts,compare,facts,trivia,indicators,polls

**Paste:**

```
statistics,geography,gdp,economy,atlas,charts,compare,quiz,facts,trivia,indicators,population,survey
```

*Why.* Exactly 100 characters, comma-separated, no spaces. Removed "data" and "rankings" because they now sit in the Subtitle and Apple indexes those already — that freed room for "quiz", "population" and "survey". "Quiz" and "trivia" cover the game intent that the Subtitle no longer carries; "survey" covers the 58 survey-based indicators and the values map; "population" is one of the highest-volume single stats people search for. Nothing here duplicates Name (BullDozer, World, in, Numbers) or Subtitle (Country, data, maps, rankings).

### Promotional text (170)  ·  156 chars

**Now:** Explore the world through data: rank 150+ indicators, compare up to 5 countries side by side, browse interactive maps and test yourself in the Guess the Country quiz.

**Paste:**

```
180 indicators, 232 countries, 46 public sources — now with a drag-to-spin globe, the 96 most valuable global brands and the Inglehart-Welzel map of values.
```

*Why.* Promotional text is the one field editable without a new build, so it should carry the numbers that move and the newest work rather than restating the description. The current text says "150+" while the live catalog holds 180 and the app's own on-screen counter prints the live figure — a visible contradiction. The globe, the brands page and the values map are the most recent features and appear nowhere in the current listing.

### Description (4000)  ·  2983 chars

**Now:** Current description opens "BullDozer turns the world into numbers you can actually explore. Compare countries across 150+ indicators…" and covers Charts & Rankings, Country Profiles, Compare, Explore, World Maps, Data Stories, Quiz, Made for Exploring, Privacy First, About the Data (1936 chars).

**Paste:**

```
BullDozer turns the world into numbers you can actually explore. 180 indicators, 232 countries, one app — with fast charts, world maps, country profiles, a spinning globe and a data quiz. Free, with no account, no ads and no tracking.

STATISTICS
Search 180 indicators across 12 topics: economy, demographics, connectivity, health, education, environment, governance, media, risk, safety, wellbeing and values. Rank every country on any of them, switch the period to watch the ranking change, and tap a bar for that country's trend over time.

WORLD MAPS
Every dataset has a world choropleth coloured by the data — tap a country to see its trend line. On the home screen the same data wraps a drag-to-spin globe.

COUNTRY PROFILES
232 countries in a searchable list. Each profile opens with a map zoomed to the country and its capital, then the coat of arms, official name, ISO codes and currency, then headline figures — GDP per capita, growth, inflation, unemployment, life expectancy, population, happiness — each with its world rank. Below that sits every available indicator for that country, grouped into Statistics and Surveys.

COMPARE AND EXPLORE
Put up to 5 countries side by side on any indicator. Plot any indicator against any other as a scatter or a bivariate map. Or press play on the animated bubble chart and watch the whole world move through the years.

POLLS AND VALUES
58 of the datasets come from international social surveys. The Inglehart-Welzel map of values places every society on two axes and colours it by cultural zone — tap any dot for the country behind it.

BUSINESS AND CITIES
The 96 most valuable global brands, ranked with their logos, plus livability and quality-of-life scores for European cities from the Eurostat perception survey.

QUIZ
"Guess the Country": real data are the hints, and the fewer hints you use, the higher your score. 197 countries in the pool, and a running session best.

TAKE THE DATA WITH YOU
Export any dataset or country profile as CSV, share a chart as an image, star the countries and indicators you follow, and set a reminder for when a dataset is next due. A freshness badge on every dataset tells you which year the figures are for and how recently they were updated.

IPHONE AND IPAD
On iPad the layout opens into columns, with the globe and the leaderboard side by side. Light and dark themes, switched with one tap. Works offline once the data has loaded.

PRIVACY
No account, no sign-up, no ads, no tracking and no analytics SDKs. Favorites, quiz scores, reminders and your theme choice stay on the device. The app simply shows you the data.

ABOUT THE DATA
Figures come from 46 public sources — among them the World Bank, IMF, WHO, Eurostat, Our World in Data, V-Dem, Gapminder, the World Happiness Report and the World Values Survey — each credited on the screen where it appears, with country summaries from Wikipedia (CC BY-SA). Everything is served through the open BullDozer feed at shpara.com/bulldozer.
```

*Why.* Fixes the stale "150+" (live catalog is 180) and adds the six real features the current copy omits entirely: the spinning globe, the bivariate map, the animated bubble player, the Inglehart-Welzel values map, the 96-brand ranking with logos, Eurostat city livability, CSV export, share-as-image, favorites, freshness badges and release reminders. Every claim is checkable against the audit: 180/232/58/96/197/46/12 are the live feed counts. Deliberate wording choices — "Works offline once the data has loaded" not "works offline"; "set a reminder for when a dataset is next due" not "alerts when new data drops", because the notification is a local calendar guess; "Data stories" is dropped from the feature list because two of the five open the website; no mention of accounts, sync, live prices, widgets or localisation, none of which exist.

### What's New (4000)  ·  765 chars

**Now:** Welcome to BullDozer — our first release on the App Store! … 150+ indicators with rankings, trends and a period switcher / Country profiles … / Side-by-side comparison of up to 5 countries / A world choropleth map for every dataset / A scatter view / Data stories with live mini charts / The "Guess the Country" quiz (441 chars).

**Paste:**

```
Welcome to BullDozer — the first release on the App Store.

• 180 indicators across 12 topics, from 46 public sources
• 232 country profiles with maps, key figures and world ranks
• A drag-to-spin globe, and a world map for every dataset
• Rankings with a period switcher and a trend chart per country
• Compare up to 5 countries, or plot any two indicators against each other
• The Inglehart-Welzel map of values, from international social surveys
• The 96 most valuable global brands, and European city livability
• "Guess the Country" — 197 countries, fewer hints for more points
• CSV export, share a chart as an image, favorites and release reminders
• An iPad layout that uses the full width, plus light and dark themes

Free, no account, no ads, no tracking.
```

*Why.* Same correction of counts, and it now lists the features shipped since the copy was written. "our first release" becomes "the first release" because the publisher is an individual trading as Azenha AI, not a team.

### App Review notes (App Review Information)  ·  2721 chars

**Now:** Current file opens: "BullDozer: World in Numbers is a fully native Flutter app — there is no webview anywhere in the binary." It also lists sources as "(WHO, World Bank, Eurostat, international surveys)".

**Paste:**

```
BullDozer: World in Numbers is a free reference app that displays public statistics. There is no account, no login, no in-app purchase, no advertising and no user-generated content. No demo credentials are needed — every screen is reachable from a cold launch.

WHAT IS NATIVE, WHAT OPENS THE WEB
The app is built in Flutter and all primary screens are rendered natively: rankings and charts, the flat world choropleth and the drag-to-spin globe, the bivariate map, the values scatter, the animated bubble player, country profiles, the flagship data stories and the quiz. Secondary reading material — the five Edu articles, two of the five data stories, the glossary and the detailed web dashboards, plus brand pages on Wikipedia — opens shpara.com in the system in-app browser via url_launcher (LaunchMode.inAppBrowserView). The app implements no WKWebView UI of its own.

DATA AND LICENSING
Figures come from public statistical datasets (World Bank, IMF, WHO, Eurostat, Our World in Data, V-Dem, Gapminder and international social surveys), served through our own open feed at shpara.com/bulldozer and credited on the screens where they appear. Country summaries are fetched from the Wikipedia REST API and labelled "Wikipedia · CC BY-SA" with a link to the article. Brand values on the business screens are credited to Kantar BrandZ / Forbes; brand logos come from Wikimedia Commons and are used for identification only, with a trademark notice on the screen. Coat-of-arms images likewise come from Wikimedia Commons.

AGE RATING
The catalog includes WHO public-health statistics such as alcohol consumption, tobacco use and suicide rates — numerical, educational data with no depiction or promotion; the questionnaire is answered accordingly.

PRIVACY
The app collects no data. Network traffic is limited to anonymous HTTPS GET requests for public JSON at shpara.com/bulldozer/data/, the Wikipedia REST summary endpoint, and images hosted on Wikimedia Commons. There are no POST requests, no identifiers, and no analytics or crash-reporting SDKs. Favorites, quiz progress, reminders and the theme choice are stored on the device only. Privacy policy: https://shpara.com/bulldozer/privacy/ — also linked from the app's side menu.

TESTING NOTES
First launch needs a connection to load the catalog; fetched data is then cached on disk and served when offline. Notifications are local only — they are scheduled on the device when the user taps the bell on a data release, and permission is requested at that moment, never at launch. There are no push notifications. The only permission string is NSPhotoLibraryAddUsageDescription, used when the user saves a shared chart image to Photos.

Contact: azenha.agent@gmail.com
```

*Why.* The current note's opening sentence is the single riskiest line in the whole package: "there is no webview anywhere in the binary" is contradicted by six call sites using url_launcher's inAppBrowserView (edu_page.dart:14, story_page.dart:258, brands_page.dart:73, main.dart:514, cultural_map_page.dart:209). A reviewer who taps any Edu card sees a web view open. Being caught overstating one thing invites scrutiny of everything else; stating it plainly costs nothing, since in-app browser links are entirely allowed. The rewrite also names the full source list, spells out that there are no POST requests and no identifiers (which is what actually supports the "Data Not Collected" declaration), and keeps the two facts most likely to prevent a rejection: notification permission is requested only on the bell tap, and first launch needs a connection.

### Support URL

**Now:** https://shpara.com/bulldozer/support/

**Paste:**

```
https://shpara.com/bulldozer/support/
```

*Why.* No change, but verify before submission that the page resolves, is in English only, and shows azenha.agent@gmail.com as the contact. A Support URL that 404s is a routine Guideline 1.5 rejection.

### Privacy Policy URL

**Now:** https://shpara.com/bulldozer/privacy/

**Paste:**

```
https://shpara.com/bulldozer/privacy/
```

*Why.* No change. Confirm the page states what the review notes state: no collection, no analytics, local-only storage of favorites/quiz/theme/reminders, and that outbound requests go to shpara.com, the Wikipedia REST API and Wikimedia Commons. English only.

### Category

**Now:** Primary Education, Secondary Reference

**Paste:**

```
Primary Reference, Secondary Education
```

*Why.* Worth flipping. The app is a reference atlas with a quiz attached, not a course or a learning tool with a curriculum — Reference is where people browsing for a world-data app actually look, and the Education top charts are dominated by school and language apps this cannot rank against. If you would rather keep the classroom framing for the App Store's editorial teams, Education primary is defensible; just do not leave it at Education while the description leads with rankings and maps.

### Age Rating

**Now:** Questionnaire answered so that everything is None/No except Alcohol, Tobacco, or Drug Use or References → Infrequent/Mild, expected result 13+

**Paste:**

```
Keep: all categories None/No, except Alcohol, Tobacco, or Drug Use or References → Infrequent/Mild. Expected result 13+.
```

*Why.* Correct as written and matched by the review-note paragraph explaining the WHO alcohol/tobacco/suicide indicators. Note that store/ios/APPSTORE-STEPS.md still says "4+" — that file is stale and should not be followed at submission time.

### Copyright

**Now:** 2026 Azenha AI

**Paste:**

```
2026 Azenha AI
```

*Why.* Matches the Individual, non-trader account. No change.

### Price

**Now:** Free

**Paste:**

```
Free
```

*Why.* See the pricing recommendation. Free requires nothing beyond the Price Schedule, and no Paid Apps agreement, so it does not block submission.

### Version / build (pre-submission blocker)

**Now:** pubspec.yaml is 1.28.0+49; the archived artefact in store/ios/ is bulldozer-v1.28.0-44.ipa and APPSTORE-listing.md is headed v1.28.0+44.

**Paste:**

```
Archive and upload a fresh build at 1.28.0+50 (or higher) before filling any of the above, and re-head store/ios/APPSTORE-listing.md to match.
```

*Why.* The listing copy above describes the current code — the globe hero, the three-view Geo tab from commit 9d391f2, and the iPad layout from 14a96be. Build 44 predates part of that, so submitting it would leave screenshots and description describing features the reviewer's binary does not have. Also update store/ios/APPSTORE-STEPS.md, which is wrong on three hard facts: it says iPhone-only with TARGETED_DEVICE_FAMILY "1" (the project now sets "1,2"), deployment target iOS 13.0 (the project sets 15.0), and age rating 4+ (it is 13+).

## Screenshots

### ipad-13

1. **Home in LANDSCAPE (2732×2048), globe mode. The wide branch must be active so the hero splits: the 360 pt globe on the left and the "HAPPIEST COUNTRIES" RankBars leaderboard on the right, with the quiz strip and the three counters (indicators / topics / 190+ countries) sitting shoulder to shoulder beneath, and the data-stories deck flowing three abreast at the bottom edge. This is essentially the existing store/screenshots/ios-ipad13l/1-home.png, re-shot on the new build.** — "The globe and the ranking, side by side."
   This is the only screen where a 13-inch display visibly buys something a phone cannot show, so it is the one frame that justifies shipping an iPad build at all. Landscape throughout the iPad set: the wide layout gives three columns at 1366 pt and only two at 1024 pt, so portrait shots understate the app.

2. **Stats in landscape. The "World records" hero showing the five superlative rows on one side and the trend companion — "WORLD <INDICATOR>", the first→last values and the trend chart — on the other, with the indicator deck running three cards per row beneath it. Let the freshness chips on the cards be legible.** — "180 indicators, three columns wide."
   Densest legible frame in the app and the clearest proof that the catalogue is large. The records hero also does the same job as the phone's shot 2 without repeating it.

3. **Biz in landscape. The brand podium with real logos and animated bar heights beside the featured leaderboard, and the two entry cards "🏆 Top brands" and "🏙️ Best cities" sharing a single row rather than stacking.** — "Brands, markets and cities."
   The most colourful iPad frame, and the side-by-side entry cards are visible evidence of a layout designed for the width rather than a stretched phone column.

4. **Geo in landscape, Countries view. The world choropleth spanning the full 1280 pt body cap on top with the "Tap a country on the map to open its profile" caption, the Countries / Compare / Two indicators chip row visible, and the 232 country cards running three abreast beneath the map.** — "232 countries, three tools, one screen."
   Shows the map at its largest and, because the three view chips are in frame, advertises Compare and Two indicators without spending another slot on them.

5. **Geo → Two indicators in landscape, Bivariate map view, with the bivariate legend and the country-count caption visible.** — "Two indicators on one map."
   Kept as its own frame because at 13 inches the bivariate map is readable in a way it never is on a phone, and it is the strongest argument for using the app on a large screen for actual analysis.

6. **Polls in landscape. The World Values Survey hero with the mini cultural scatter beside the ranking, and the survey dataset deck running three abreast below.** — "58 datasets from world surveys."
   Rounds out the tab tour with the survey side of the catalogue. It is ranked last of the six because MiniCulturalMap is fixed at 170 pt and does not grow with the screen, so the frame is carried by the deck beneath rather than the hero.

### iphone-6.9

1. **Home, portrait, hero in Globe mode. Must show, in one frame: the BullDozer wordmark and the tagline, the "Featured · World Happiness Report" tag, the headline "<Country> leads the happiness ranking", the coloured globe mid-spin with the Less happy → Happier legend, and the caption "Drag to spin · tap a country for its profile". Wait for the auto-spin to land on a rotation showing Europe, Africa and part of Asia — a face full of countries, not the Pacific. Dark theme.** — "Spin the globe. Tap any country."
   This is the only screenshot most people will ever see, and it has one job: prove in half a second that this is real data on a real globe, not another trivia app. The globe is the single most distinctive thing in the binary and it appears nowhere in the current listing. Dark theme because the choropleth colours separate more strongly against it and it differentiates from the white-background reference apps sitting next to it in search results.

2. **Stats → dataset detail (DatasetPage) for a widely understood indicator — Life expectancy or GDP per capita (PPP) — in Bars view, sort Highest, latest period. Show the summary line and the "<source> · <license> · <unit>" credit, the period chips, the Bars/Map toggle, and at least eight ranked country bars with flags. Freshness chip visible.** — "Rank every country on 180 indicators."
   Shot two must answer "what do I get" concretely. A ranked bar list with flags, a unit and a named source is the app's core loop in one image, and the visible source credit is the trust signal that separates it from unsourced fact apps.

3. **Geo → country profile for a country with rich data and a recognisable outline (Japan, Brazil or Portugal). Show the locator map with the capital marked, the coat of arms and the ISO/currency/capital badges, and the full row of KPI badges with their "#<rank> of <total>" ranks. Scroll so the top of the "📊 Statistics" section is just visible.** — "Every country, in one profile."
   The third shot is the last one visible without swiping in most search layouts. The country profile is the screen users will actually return to, and the "#12 of 190" rank chips communicate the app's whole premise — a number is only interesting next to every other country's number.

4. **Geo → Compare view with 5 countries selected on one indicator (e.g. Inflation or GDP per capita), ranked bars drawn, all five flag chips visible above the chart.** — "Up to five countries, side by side."
   Comparison is the most commonly searched job-to-be-done in this category and the one feature name that appears in Keywords. Five filled slots shows the ceiling without a word of copy.

5. **Geo → Two indicators, Bivariate map view, with a pairing that reads instantly (GDP per capita × Life expectancy). Show the bivariate legend and the "<n> countries · brightest = high on both" caption.** — "Plot any indicator against any other."
   The bivariate map is the most visually unusual frame in the app and signals analytical depth to the users most likely to leave a good review. It appears nowhere in the current listing.

6. **Polls → Map of values (pushed from the hero). Show the title "The Inglehart-Welzel map", the full scatter with cultural-zone colours, and the zone legend. Do not crop the axis labels.** — "The Inglehart-Welzel map of values."
   Proves the app carries genuine social-survey research and not just economic indicators, which is what justifies the Polls tab and the 58 survey datasets in the description.

7. **Biz → Top brands, scrolled to the top so ranks 1–8 are visible with their logos on white chips, plus the "Most valuable global brands · <year> · brand value US$ bn" header line and the trademark credit at the bottom of the frame if it fits.** — "The 96 most valuable global brands."
   The only screen with real logos, so it is the most colourful frame in the set and gives the eye somewhere to land after five data screens. Keep the trademark credit visible — it is also the answer to any App Review question about the logos.

8. **Country Quiz mid-round: the "Which country is this?" prompt, two or three data clues revealed, the "worth <n>" points chip and the "One more hint (−1 point)" button. Do not use a result screen with a low score or the chimpanzee verdict.** — "Guess the country from its data."
   Closes the set on the one screen that converts a browser into a daily user, and it is the payoff for the "quiz" and "trivia" keywords. Mid-round rather than results, because the tension of a partly revealed answer is what makes someone tap Get.

## Adversarial pass

Verdict: **revise**

### Pricing

- DSA trader status is missing from every paid option. The account is Individual + non-trader, which only holds while the app is free with no IAP and no ads. Options B, C and D all make the account commercial and force the trader flip in App Store Connect -> Business -> Agreements -> Compliance, which publishes a trader name, address and phone number on every EU storefront listing. That flip is account-level, so it also changes the already-submitted Madeira Ativa listing, and without a CTT apartado opened first the home address goes public. The options only budget 'Paid Apps agreement, banking and tax'. Any of B/C/D is therefore a two-app decision plus a postal-box errand, not a pricing checkbox.
- Source licences make monetisation a legal problem, not just a conversion problem, and no option mentions it. In the live feed (/Users/kirillshpara/Projects/bulldozer/dist/data): 7 WHO Global Health Observatory datasets are CC BY-NC-SA 3.0 IGO (non-commercial AND share-alike), and roughly 25 more carry terms like 'Free for research use (GESIS)' (Eurobarometer), 'Free for research use (Arab Barometer)', 'Free for research use (DHS Program, registration required)', 'Open - academic use' (QoG), 'Public - Hofstede model'. A $2.99 price, or even a tip jar, turns the whole catalogue into commercial redistribution of NC/academic-terms data. This — not conversion rates — is the strongest argument for Free, and it is the one argument the package does not make.
- Option D's rationale misreads its own evidence. It cites 'the twelve entries in releases.json' as a hint of a publishing rhythm. Those twelve entries are other institutions' release calendars (IMF WEO 'April & October', World Bank GEP 'January & June', World Happiness Report...), i.e. a schedule of when third parties publish, not a record or commitment of BullDozer shipping anything. There is no evidence in the repo of a cadence a subscriber would be buying, so 'the story is at least tellable' is not supported.
- Option C claims 'zero code changes' and it is true for StoreKit, but the app is already built, uploaded (build 1.28.0+44, Apple ID 6797664814) and covered by the Free Apps Agreement only. Switching to paid means a new agreement, Portuguese tax setup for an individual, the trader flip above, plus a description that never mentions a price and screenshots that must now carry the entire purchase decision for an unknown developer with no ratings. Priced correctly against effort, C is the worst of the four, not the 'simplest real monetisation'.
- The revisit plan has no instrument. 'Revisit after about six months of real install data' is proposed for an app that by design ships no analytics and declares Data Not Collected, so the only available signal is App Store Connect units and ratings. Either state now the concrete threshold that would trigger Option B (e.g. 5k installs and 50 ratings), or the six-month review will be a vibe check.
- Option B's risk section understates one thing: adding IAP to this specific app means putting a paid product in front of a catalogue whose 46 credited sources are all other people's public data, on a screen that already prints 'Values: Kantar BrandZ / Forbes, via Wikipedia'. That is the exact shape App Review looks at twice under 3.1.1/3.1.2. The recommendation to keep it Free is right; the reason should include this.

### Guideline risk

- 5.2.5 (Apple trademarks) and 5.2.1 (third-party IP) — iPhone screenshot 7 and iPad screenshot 3 put third-party brand logos into App Store marketing artwork. brands.json ranks 1-8 are Google, Apple, Microsoft, Amazon, Nvidia, Facebook, Instagram, Tencent, every one with a logo URL, and the shot spec explicitly says 'ranks 1-8 visible with their logos'. Using logos in-app for identification (with the trademark line the app already prints) is defensible; putting the Apple logo and Meta/Google marks in your store screenshots is a known removal/rejection trigger and implies affiliation. Replace both slots — the Eurostat cities screen or the brand ranking with logos suppressed — or crop above the logo column.
- 2.3 (accurate metadata) — the rewritten App Review notes repeat the exact failure they were written to fix. 'Network traffic is limited to anonymous HTTPS GET requests for public JSON at shpara.com/bulldozer/data/, the Wikipedia REST summary endpoint, and images hosted on Wikimedia Commons' is contradicted by main.dart:266 (side menu opens https://github.com/kirshp/bulldozer-app), main.dart:276 (mailto:azenha.agent@gmail.com) and countries_page.dart:754 (opens en.wikipedia.org/wiki/<article> externally). Drop the word 'limited' or list all destinations. The webview correction itself is right and verified: six inAppBrowserView call sites at edu_page.dart:14, story_page.dart:258, brands_page.dart:73, main.dart:514, cultural_map_page.dart:209.
- 4.2 / 4.2.2 (minimum functionality) — the notes call the Edu articles 'secondary reading material', but Edu is a top-level tab in the six-tab bar (Home, Stats, Biz, Polls, Geo, Edu) and every card on it calls launchUrl(inAppBrowserView) to shpara.com (edu_page.dart:14). A reviewer who taps the last tab sees a screen that is nothing but web links. Say that plainly in the notes and lead with the native inventory; and do not upload an Edu screenshot (the existing sets all contain 6-edu.png).
- 5.2 content rights, and a missing ASC answer — the App Information 'Content Rights' question is absent from the package entirely. It must be Yes here: Wikipedia CC BY-SA summaries, Wikimedia Commons logos and coats of arms, Kantar BrandZ / Forbes brand values, WHO CC BY-NC-SA data, V-Dem CC BY-SA. Ativa was submitted with Content Rights = Yes; leaving BullDozer at No while the app prints those credits on screen is a clean rejection.
- Age rating — 13+ with only Alcohol/Tobacco/Drugs at Infrequent/Mild is probably right, but two questionnaire items are unaddressed. (a) Medical/Treatment Information: the catalogue carries WHO suicide rates, alcohol and tobacco use, and DHS contraception. (b) Unrestricted Web Access: the in-app browser opens Wikipedia article pages (brands_page.dart:72), from which the open web is reachable. Answer both deliberately — an 'unrestricted web access' finding forces 18+, and a reviewer who disputes a 'None' re-rates the app for you.
- Upload-time blocker not in the checklist: there is no PrivacyInfo.xcprivacy anywhere under ios/ and zero references in Runner.xcodeproj/project.pbxproj, while the app itself uses file APIs (api.dart:46, favorites_store.dart:33, notify.dart:33, theme.dart:40). Check the delivery email from the 04.08 upload for ITMS-91053 / ITMS-91061 warnings; if present, add an app-target privacy manifest declaring the file-timestamp reason before the next archive.
- Verified clean, for the record: Support URL and Privacy Policy URL both return HTTP 200 (Guideline 1.5 satisfied); ITSAppUsesNonExemptEncryption=false is already in Info.plist; notification permission really is requested only on the bell tap, not at launch (notify.dart, DarwinInitializationSettings with all request*Permission: false); NSPhotoLibraryAddUsageDescription is the only usage string; no analytics or crash SDK in pubspec (http, url_launcher, path_provider, flutter_local_notifications, flutter_timezone, timezone, share_plus, fl_chart), so Data Not Collected holds; no IAP plugin, confirming Options B and D need code that does not exist; TARGETED_DEVICE_FAMILY is '1,2' and IPHONEOS_DEPLOYMENT_TARGET is 15.0, so the package is right that APPSTORE-STEPS.md is stale on iPad, deployment target and 4+.

### Copy

- No character limit is exceeded — I counted all of them: Name 27/30, Subtitle 29/30, Keywords exactly 100/100, Promotional text 156/170, Description 2983/4000, What's New 765/4000. Keywords at exactly 100 leaves no margin, so paste carefully (no spaces after commas). No competitor names, no price mentions, no non-English text in any proposed field. That part is sound.
- Metadata contradicts the app's own first screen. The description and captions say '232 countries', but main.dart:731 hard-codes a stat box reading '190+ countries' — visible in store/screenshots/ios-6.9/1-home.png, the frame proposed as screenshot 1, and in the iPad shot 1 spec ('the three counters'). The package's own rationale claims 'the app's own on-screen counter prints the live figure'; that is true only for indicators (catalog.length) and false for countries. Either change the literal to '232' or drop 232 from the copy.
- Screenshot capture hazard on the same counter: the baked fallback catalogue in lib/catalog.dart has 154 entries while the live feed has 180 (verified: shpara.com/bulldozer/data/catalog.json returns 180 datasets, country-index.json returns 232). Any shot taken before the live catalog loads shows '154 indicators' against copy that says 180.
- Unbacked claim, cities: 'livability and quality-of-life scores for European cities from the Eurostat perception survey.' cities.json's headline metric is labelled in the feed itself as 'Overall livability ... BullDozer composite - mean perc[eptions]'. The composite is yours, not Eurostat's. Say 'a livability composite we build from the Eurostat perception survey' — otherwise it breaks the wedge claim that every figure names its public source.
- Over-absolute claim, profiles: 'Each profile opens with a map zoomed to the country and its capital, then the coat of arms...' country-meta.json has capital and coat-of-arms for 256 of 268 entries, and 3 of the 232 indexed countries have no meta record at all. Also 'official name' renders only when country.official is non-empty (countries_page.dart:549). Use 'Most profiles open with...'.
- Topic list mismatch: the description names 12 topics ending in 'values', but the in-app chip is '🧭 Attitudes & values' and the feed key is 'attitudes' (charts_page.dart:40). A reviewer comparing the list to the chips sees eleven matches and one invented name. Use the app's own label.
- '58 of the datasets come from international social surveys' — 58 is correct (kind='survey'), but the set includes single-country panels (8 RLMS-HSE datasets) and EU-only instruments (Eurobarometer, EU-SILC). 'international and national social surveys' is accurate and costs three words.
- Promotional text says 'now with a drag-to-spin globe, the 96 most valuable global brands and the Inglehart-Welzel map of values.' On a first release there is no 'now with' — nobody has a previous version. Also the brands ranking is Kantar BrandZ/Forbes via Wikipedia, so 'the 96 most valuable global brands' stated flat in both Promo and Description reads as your own authoritative ranking; the app screen credits it, the metadata does not.
- SCREENSHOT 1 will not make a stranger tap Get, and I looked at the actual file. In store/screenshots/ios-6.9/1-home.png the top 18% is wordmark plus 'Bulldoze the noise. Mine the signal.' — jargon that tells a newcomer nothing. The globe is a single-hue amber sphere; at App Store search-thumbnail width (~150px) the legend ('Less happy -> Happier') and the caption line are unreadable, so the frame reads as a generic orange ball. The only numbers on the screen — 180 / 12 / 190+ — sit 47% down the frame, and one of them is wrong per the item above. The current capture is centred on the Atlantic: roughly half the visible disc is empty ocean and Greenland renders grey (no data). Either lead with the ranked-bars frame (current shot 2, which shows country names, figures, flags and a named source — the actual promise) or re-shoot the globe centred on Europe/Africa/Asia with a burned-in headline such as '180 indicators. 232 countries. Free.'
- The 14 screenshot 'captions' in this plan do not exist anywhere. Every file in store/screenshots/* is a raw device capture at exact slot size with no text overlay, and there is no overlay template in the repo. Either build the caption frame (which is also the fix for the unreadable-at-thumbnail problem above) or delete the captions from the plan, because as written they never reach the store.
- iPad slot dimensions are mixed and the plan picks the older one. store/screenshots/ios-ipad13 is 2064x2752 (13-inch generation) while ios-ipad13l is 2732x2048 (12.9-inch generation), and the plan specifies 2732x2048 for all six landscape shots. All screenshots in one slot must share dimensions; confirm in the live record which the 13-inch slot accepts and re-shoot one set rather than assuming. Your own APPSTORE-STEPS.md calls wrong dimensions 'the most common mechanical rejection'. Related: the Ativa record exposed a 6.5-inch (1284x2778) slot, not 6.9-inch — verify which slot record 6797664814 shows before shooting an 8-frame 6.9-only set.
- Name field: the package says 'no change', but store/ios/APPSTORE-STEPS.md and the app-record creation step use 'BullDozer — World in Numbers' (em dash) while fields/name.txt and this package use 'BullDozer: World in Numbers' (colon). Check what the existing record actually holds before assuming there is nothing to do.
- Version blocker is correctly identified and I confirmed it: pubspec.yaml is 1.28.0+49, the archived artefact is bulldozer-v1.28.0-44.ipa, and the uploaded build is 44. Do not fill any of this copy against build 44 — the globe hero, the iPad wide layout and the three-view Geo tab the description sells are not all in it.
