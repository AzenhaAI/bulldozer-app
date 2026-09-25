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
