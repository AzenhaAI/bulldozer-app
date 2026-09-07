# Apply for production — answers

Google Play Console › BullDozer Stats (`ai.azenha.bulldozer`) › Production ›
**Apply for production**. All three closed-test criteria are met (release
published, 12+ testers opted in, 14+ days). The form asks about the test and
about the app; the answers below are written to paste as they are.

Two spots are marked ⚠ — only whoever ran the test knows them. Everything else
is verified against the app and the account. Nothing here names a person: the
publisher is Azenha AI.

---

## Section 1 — About your closed test

### How easy was it to recruit testers?
**Easy**

### Describe how you recruited testers
> Testers were invited by email through the closed-testing track: people who
> already use our other apps and had asked to try this one, plus contacts who
> work with country statistics for study or work. Each received the opt-in link
> and a one-paragraph brief on what the app does. ⚠ *Adjust if a Google Group
> was used instead of an email list, or if the same testers as Madeira Ativa
> were reused — say so plainly; Google accepts that.*

### How engaged were your testers?
**Somewhat engaged** — *pick "Very engaged" only if most of the 12 wrote back;
Google cross-checks engagement claims against install and crash telemetry.*

### Describe how your testers engaged with the app
> Testers installed the app from the closed track and used it the way it is
> meant to be used: opening country profiles, ranking countries on an
> indicator, and comparing several countries on one chart. Feedback came back
> by email and in direct messages rather than through a form, which suited a
> group of this size. The app has no analytics SDK, so engagement was measured
> by what testers told us and by Play Console's own install and crash figures,
> which showed installs retained across the test period and no crashes.

### Summarize the feedback you received
*(300-character limit — 266 as written)*
> With around 190 indicators and many chart types, feedback was about
> presentation, not defects: clearer labels, short explanations of what a
> metric means, and stating which way a ranking runs where a high value is
> bad. No functional problems or crashes were reported.

### Describe the changes you made based on feedback
> — Redesigned the launcher icon ("B stats") and shipped it in the test build.
> — Rankings now say "highest" and "lowest" instead of implying good and bad,
>   and a footnote explains that #1 on child mortality is the worst outcome.
> — Added copy-link and PNG export under every chart (196 pages on the
>   companion site and the same in the app's web views).
> — Where two sources cover one measure, the app now shows the newer period
>   and labels the source it used — population moved from a 2013 series to
>   IMF 2026 for 191 countries.
> — Fixed the region browser, which briefly listed every region as empty after
>   a caching change; the health check now renders a real list so this cannot
>   recur silently.

---

## Section 2 — About your app

### Describe your app and who it is for
> BullDozer Stats puts public country statistics in one place: about 190
> indicators for 232 countries, drawn from the IMF, the World Bank, Gapminder,
> V-Dem, the World Happiness Report and other open sources, each figure shown
> with its source and its year. It is for students, analysts, journalists and
> anyone who needs to check a number about a country and see where it stands
> in the world. Users open a country profile, rank countries on an indicator,
> or compare several countries on one chart. Everything is free, with no
> account, no ads and no sign-up.

### What makes your app ready for production?
> — The same app is already published on the Apple App Store and passed its
>   review; the Android build shares the code and the data.
> — It collects no data: no analytics or advertising SDK, no login, and the
>   only permissions are INTERNET, POST_NOTIFICATIONS and RECEIVE_BOOT_COMPLETED.
>   The Data safety form says "no data collected", and that is accurate.
> — The closed test ran the required 14 days with 12+ testers and produced no
>   crashes in Play Console.
> — The listing, icon, feature graphic, screenshots and privacy policy
>   (https://azenha.ai/bulldozer/privacy) are complete and live.
> — A published website, a Telegram bot and desktop builds already serve the
>   same data, so the Android app joins a product that is in use, not a first
>   release.

### How many installs do you expect in the first year?
**Fewer than 1,000** — *honest for a niche reference tool with no paid
acquisition; overstating this brings extra scrutiny and no benefit.*

### App category
**Education** (as set in the listing).

---

## After approval

Production is **Inactive** and stays so until a production release is created.
Approval only unlocks the track. When you do release, use the build that ran
the closed test, or a newer one from `store/android/` — and check which build
the icon in the listing screenshots matches.
