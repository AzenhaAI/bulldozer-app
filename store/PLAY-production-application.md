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

*The form has two 300-character fields here, not one description.*

### Who is the intended audience of your app?
*(297 characters)*
> Students, analysts, journalists and anyone who needs to check a figure about a country and see where it stands in the world: GDP, life expectancy, democracy scores, happiness and about 190 other indicators for 232 countries. Free, no account, no ads, so it suits casual and professional use alike.

### Describe how your app provides value to users
*(292 characters)*
> One place for public country statistics otherwise spread across the IMF, World Bank, Gapminder, V-Dem and others. Every figure shows its source and year. Users open a country profile, rank countries on any indicator, or compare several on one chart, and what was loaded keeps working offline.

## Section 3 — Your production readiness

*Two 300-character fields.*

### What changes did you make to your app based on what you learned during your closed test?
*(293 characters)*
> Presentation, as the feedback asked: rankings now say highest and lowest rather than implying best and worst, with a note where a high value is bad; labels and short explanations were added to metrics; where two sources cover one measure the newer year is shown; the launcher icon was redrawn.

### How did you decide that your app is ready for production?
*(296 characters)*
> The closed test ran the full period with 12+ testers and no crashes in Play Console, and every point raised was resolved. The same app is already published on the App Store after review. It collects no data, needs no account, and the listing, screenshots and privacy policy are complete and live.

## After approval

Production is **Inactive** and stays so until a production release is created.
Approval only unlocks the track. When you do release, use the build that ran
the closed test, or a newer one from `store/android/` — and check which build
the icon in the listing screenshots matches.
