# In-app events — rolling plan

One event a month, tied to a real data release, each with a deep link to its
screen (`bulldozerstats://open/...`, build 83+). App Store: `_stores/asc_event.py`
with an `event-<name>.json` here, then a review submission. Google Play:
Promotional content (Grow users), same text and 16:9 card. An event lasts at
most 31 days and may be announced up to 14 days before it starts.

Dates of releases are the publishers' usual months; check the release has
actually happened and the data is in the app before submitting.

| Window | Event | Data it rests on | Link |
|---|---|---|---|
| 20 Nov – 18 Dec 2026 | Economy this week | weekly table, IMF WEO Oct 2026 | open/economy |
| Dec 2026 – Jan 2027 | 2026 in numbers (year review) | records across Stats/Biz/Polls | open/stats |
| late Jan – Feb 2027 | IMF outlook update | IMF WEO Update (January) | open/dataset/imf-gdp-growth |
| Feb – Mar 2027 | Corruption Perceptions Index 2026 | Transparency International (Feb) | open/dataset/cpi-corruption-perceptions |
| Mar – Apr 2027 | Happiest countries 2027 | World Happiness Report (~20 Mar) | open/dataset/whr-happiness |
| Apr – May 2027 | IMF April outlook | IMF WEO (April) | open/economy |
| May 2027 | Freedom of expression | V-Dem dataset (March) | open/dataset/v-dem-v2x-freexp-altinf |
| Jun 2027 | Global Peace Index | IEP (June) | open/dataset/gpi-global-peace |

All slugs checked against lib/catalog.dart on 15 Nov 2026.
