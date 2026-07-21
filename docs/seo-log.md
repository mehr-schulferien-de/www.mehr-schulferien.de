# SEO Work Log

Dated log of SEO changes with baseline numbers and verification criteria,
so future sessions can check whether the work paid off. Data source:
Google Search Console (GSC), property `https://www.mehr-schulferien.de`.

## 2026-07-17: Federal state head terms

### Problem / baseline (GSC, 12 months up to 2026-07)

- Traffic came almost entirely from year-less **city** pages (about 2/3)
  and **school** pages (about 1/3). City pages rank positions 1-5 for
  queries like "ferien lüneburg", "aachen ferien".
- **Federal state Ferien pages were effectively invisible**: not a single
  `/bundesland/` page in the top 1000 pages by clicks, and no
  "schulferien <bundesland>" head query in the top 1000 queries at a
  clickable position. Example: "schulferien 2027 sachsen" at position 53.
- The head terms (e.g. "schulferien brandenburg") are the largest search
  volume segment for this site's topic, so this was the biggest gap.
- Bridge day state pages ranked positions 7-18 for "brückentage <jahr>
  <bundesland>" with CTR mostly below 2%.
- Diagnosis: state content only existed on year-suffixed URLs
  (`/bundesland/brandenburg/2026`) which compete with each other and
  restart every January; the year-less URL was a temporary redirect. The
  city pages, which do rank, are year-less evergreen URLs.

### Changes (shipped 2026-07-17, v4.31.0)

1. **Evergreen state pages**: `/ferien/d/bundesland/<slug>` is now a real
   page (current + next school year, self-canonical, in the sitemap with
   priority 0.9) instead of a redirect.
2. Year pages: self-referencing canonicals, og:image, large Twitter card.
3. Meta descriptions: colloquial vacation names ("Die Sommerferien in
   Brandenburg laufen noch 36 Tage") instead of broken grammar.
4. Bridge day pages: benefit-led titles/descriptions with the number of
   opportunities, plus canonical tags.
5. Removed the dead Universal Analytics snippet (UA shut down mid-2023;
   the site currently has NO on-page analytics; GSC is the data source).

### How to verify success

Export GSC performance data (last 3 or 12 months) and check:

| Check | Baseline 2026-07 | Success looks like |
|---|---|---|
| Evergreen URLs (`/bundesland/<slug>`, no year) indexed and gathering impressions | 0 (URLs did not exist as pages) | Impressions within weeks, clicks within 2-3 months |
| Position for "schulferien <bundesland>" head queries | Not in top 1000 queries / position 50+ | Any appearance in top 1000, then climbing toward top 20 |
| `/bundesland/` pages in top-1000 pages report | None | Several states appear |
| CTR on "brückentage <jahr> <bundesland>" queries | Mostly < 2% at positions 7-18 | Noticeably above baseline at similar positions |

Suggested checkpoints: **October 2026** (autumn peak season) and
**January 2027** (strongest month of the year). Compare against this
baseline, then append a dated entry here with the outcome.

### Open follow-ups

- ~~Main navigation still links year pages, not the evergreen pages.~~
  Done 2026-07-19 (see below).
- If evergreen pages gain traction, consider consolidating year pages
  into them via 301, as was done for cities (the proven pattern here).
- No GA4 on the site; add gtag.js when a measurement ID is available.

## 2026-07-19: Index diet (Phase 1) and striking-distance work (Phase 2)

### Problem / baseline (GSC + Ahrefs, 2026-07-19)

Google knew ~267k URLs but indexed only ~55k (about 20%), and Ahrefs saw
only a few hundred pages earning organic traffic. Index coverage broke
down as:

- **~107k URLs blocked by robots.txt**: old year pages (2019-2025) for
  cities/schools/bridge days plus `/land/*`. The blocks were self-
  defeating: the URLs already 301 (cities, schools) but a robots-blocked
  URL is never recrawled, so Google could not see the redirects and the
  URLs sat in the index forever.
- **~79k "crawled - currently not indexed"**: dominated by two thin page
  families - `/urlaubsplaner/<state>/<N>-tage/<year>` combinatorics
  (16 states x ~60 day counts x years x 2 variants) and per-school
  `/briefe/...` letter pages (~30k schools x 4 variants).
- The sitemap capped every category at 10,000 URLs, so ~20k school pages
  were missing from it while thin urlaubsplaner pages were included.
- State year pages for past years still rendered 200 (duplicate,
  outdated); old bridge-day year pages 404ed; legacy redirects went out
  as 302 instead of 301.
- Authority remains the strategic bottleneck: Ahrefs DR 10, ~157
  referring domains (only ~50 followed).
- Striking distance (GSC, 3 months): the largest impression volumes at
  positions 4-20 were the Germany-wide and per-state
  "brückentage 2026/2027" queries (positions ~7-16), served only by
  state pages - there was no national Brückentage page. "ferien
  <bundesland> 2027" head terms still ranked 45+ (the evergreen state
  pages from 2026-07-17 need time). "urlaubsplanung 2027 <bundesland>"
  brought a trickle via urlaubsplaner pages.

### Changes (shipped 2026-07-19)

**Phase 1 - index diet:**

1. robots.txt is static again: no year-based Disallows, no `/land/`
   block. Only true non-content (api, admin, wiki, ads, vcards) stays
   blocked, so crawlers can finally see all 301s.
2. Past-year 301s: state year pages and bridge-day year pages older than
   the current year now 301 to the evergreen state page / current-year
   bridge-day page. The `:redirects` pipeline default went from 302 to
   301.
3. `noindex` on thin tool pages: all urlaubsplaner day-count pages and
   all per-school briefe pages (documents index + 3 letter LiveViews).
4. Sitemap rebuilt as a sitemap index (`/sitemap.xml`) with per-type
   children: `sitemap-static.xml`, `sitemap-bundeslaender.xml`,
   `sitemap-staedte.xml` (now ALL ~14.6k cities, not only those with
   schools), `sitemap-schulen.xml` (all ~30k non-quarantined schools,
   10k cap removed). Thin pages are out. GSC now reports indexing
   coverage per page type.

**Phase 2 - striking distance:**

5. National Brückentage overview `/brueckentage/d/<year>` targeting the
   "brückentage <jahr>" head terms: per-state cards with opportunity
   counts, linked from every state bridge-day page; in the sitemap for
   current + next year. (Route must stay above the vacation catch-alls
   in the router - `constraints:` on routes are not enforced by
   Phoenix.)
6. Main nav (both implementations): the current-year tab now links the
   evergreen state pages, funneling sitewide link equity to the
   head-term URLs.

### How to verify success

| Check | Baseline 2026-07 | Success looks like |
|---|---|---|
| "Blocked by robots.txt" in GSC page indexing | ~107k | Falling steadily; near zero within ~3-6 months as redirects get seen |
| "Crawled - currently not indexed" | ~79k | Falling as urlaubsplaner/briefe pages drop out (they move to "Excluded by noindex", which is fine) |
| Indexed pages / known pages ratio | ~55k / ~267k (20%) | Known-URL total shrinks toward ~60-80k; ratio above 60% |
| Per-type sitemap coverage (GSC > Sitemaps) | n/a (new) | schulen + staedte children reach high indexed ratios |
| "brückentage <jahr>" (national queries) | Pos ~10-16 via state pages | National page ranks; positions climbing toward top 5 |
| "schulferien <bundesland>" head terms | Pos 45+ | See 2026-07-17 checkpoints (Oct 2026, Jan 2027) |

### Content roadmap (from GSC query analysis, 2026-07-19)

Ahrefs Content Gap is unavailable on the current plan, so this roadmap
is built from GSC striking-distance data. In rough priority order:

1. **Evergreen Brückentage state pages**: `/brueckentage/d/bundesland/
   <slug>` is still a 307 redirect to the current year - make it a real
   page (current + next year), mirroring the proven state-page pattern.
2. **Feiertage pages per state**: "feiertage <bundesland> <jahr>" is a
   large competitor traffic segment; the site has no dedicated
   Feiertage pages (only the ist-heute widgets).
3. **FAQ blocks for question queries**: "wann sind <saison>ferien",
   "wann fängt die schule wieder an" etc. appear at positions 7-9;
   extend the season overview and state pages with FAQ content/schema.
4. **Evergreen Urlaubsplaner state page**: one indexable
   `/urlaubsplaner/<state>` landing page per state for "urlaubsplanung
   <bundesland>"; day-count/year variants stay noindexed.
5. **Season-state URL slugs**: the generated season pages use slugs like
   `osternferien`/`weihnachtenferien`; searchers use "osterferien"/
   "weihnachtsferien". Check whether the grammatical slugs should be
   the canonical URLs (with 301s from the old ones).
6. **National ist-heute pages**: "ist heute feiertag" (no state) has
   real volume; a country-level page could ask for/detect the state.
7. **Authority (Phase 3)**: DR 10 is the ceiling on all head terms.
   Data-driven PR (16 regional angles per story), an embeddable
   Ferien-widget for schools/municipalities, and promoting the API to
   developer communities are the realistic link sources for this niche.

## 2026-07-21: Full analysis on upgraded Ahrefs plan (Content Gap + GSC Insights)

Ahrefs subscription upgraded; Content Gap and GSC Insights (connected
GSC property) are now available. Snapshot of all numbers, then a
re-prioritized roadmap.

### Data snapshot

**GSC, last 3 months (to 2026-07-19):** 49,800 clicks / 1.63M
impressions / CTR 3.1% / avg position 10.4. That is ~550 clicks/day.
Ahrefs' estimate (603/month) undercounts real traffic ~27x because the
long-tail school/city queries are below its keyword database radar -
never treat Ahrefs traffic numbers as absolute for this site.

**Ahrefs:** DR 10 (fell from 15 during June - watch), UR 9. 489
backlinks / 167 ref domains (only 52 followed, 31%; 99.8% of links have
UR < 10). 533 tracked keywords, 771 by-location rows; tracked keyword
count roughly halved from Feb to May (seasonal Easter drop + school
pages losing positions in May/June). 256 pages with traffic; none above
1,000/month. Crawl: 191k pages crawled, 82.7% HTTP 200, 17.2%
redirects, 148 404s, 34 5xx.

**Index status (GSC, data through 10.07, i.e. BEFORE the 19.07 index
diet deploy):** 54.6k indexed / 267k known. Blocked by robots.txt
107,379; crawled-not-indexed 79,086; 404 10,716; redirect 5,749;
noindex 114 (will explode as urlaubsplaner/briefe noindex gets
recrawled - that is expected and fine). Sitemap index healthy: read
21.07, 44,846 URLs discovered. Verification checkpoints from 2026-07-19
stand unchanged.

**Evergreen state pages are working** (5 weeks in): the Thüringen
evergreen page is now the site's top page in Ahrefs (68/month est.);
"osterferien thüringen 2026" (8.5K vol) moved 41→24, "ferien thüringen
2025" entered at 26. National + state Brückentage queries sit at
positions 7-16 with real impressions ("brückentage 2027 sachsen" pos
6.9, CTR 2.9%). The pattern is validated; the remaining head-term gap
is time + internal links + authority.

**Content Gap vs schulferien.org (DE, they top-10, we not in top 100):
23,294 keywords.** The gap clusters, with monthly volumes:

| Cluster | Examples (volume) | Our asset |
|---|---|---|
| ferien/schulferien state+year | ferien bayern 2026 (265K), ferien niedersachsen 2025 (190K) | evergreen state pages, too young/weak |
| Season + state (+year) | weihnachtsferien nrw 2025 (185K), pfingstferien bayern 2026 (163K), osterferien bayern 2026 (87K) | season pages exist but crippled (below) |
| **Feiertage** | feiertage nrw 2026 (146K), feiertage 2026 (94K), feiertage bayern 2026 (91K), feiertage hessen 2026 (85K) | **nothing** - 314 GSC queries land at pos 40-70 on wrong pages |
| National season | herbstferien 2024 (215K), sommerferien 2026 (93K), sommerferien nrw (99K) | none - random city pages soak these at pos 4-9 with 0% CTR |
| Kalender/generic | kalender 2026 (334K), ostern 2026 (497K), pfingsten 2026 (344K) | none (future option, off-topic-ish) |

KD on almost all of these is 0-8: the blocker is authority + page
quality, not keyword difficulty.

**Season pages are structurally crippled** (worst technical finding):

1. URL slugs are generated as `#{db_slug}ferien`, producing
   **osternferien, weihnachtenferien, pfingstenferien, fruehjahrferien,
   himmelfahrtferien** - words nobody searches. Live sitemap counts:
   32 weihnachtenferien, 30 osternferien, 6 pfingstenferien URLs.
2. The CORRECT terms (`/osterferien/hessen/2026`,
   `/weihnachtsferien/rheinland-pfalz/2026`) exist as URLs but
   **302-redirect to the generic state year page** - searchers' exact
   phrases bounce away while the content sits on the wrong slug.
3. Year-less season URLs (`/sommerferien/niedersachsen`) are 302s to
   the current year - the exact anti-pattern that kept state pages
   invisible until 2026-07-17.
4. Past-year season pages render 200 forever
   (`/osternferien/hessen/2022` is still live) - stale duplicates
   competing with current pages.

Same evergreen gap for Brückentage: `/brueckentage/d/bundesland/<slug>`
is still a 302 to the year page (roadmap item 1 from 2026-07-19,
unchanged).

**School pages: huge impressions, ~zero CTR.** Dozens of school-name
queries with 600-3,400 impressions each at positions 6-11 and 0-0.6%
CTR (heinrich schütz schule 3,420 impr / 2 clicks; oberschule pulsnitz
2,739 / 1; ohain schule 2,716 / 0). These are navigational searches for
the school's own website; we rank but give no reason to click. Titles
that lead with the concrete benefit ("Nächste Ferien: ... ab 23.07.")
are the only realistic lever; expectations moderate.

### Re-prioritized roadmap (supersedes 2026-07-19 ordering)

**P1 - season + bridge day URL structure (engineering, proven pattern):**
1. Correct season slugs as canonical URLs (osterferien,
   weihnachtsferien, pfingstferien, fruehjahrsferien) with 301s from
   the old grammatical-monster slugs; keep DB slugs, map at URL layer.
2. Evergreen season-state pages (`/sommerferien/<state>` as real page,
   current + next year, self-canonical, sitemap) - replicate the state
   page pattern.
3. Evergreen Brückentage state pages (same).
4. Past-year season pages 301 to the evergreen season page.

**P2 - Feiertage page family (largest new-content lever):**
`/feiertage/d/bundesland/<slug>` evergreen + per-year, national
`/feiertage/d/<year>`; holiday data already exists in periods. Internal
links from every state page + nav. Targets the 85-146K volume cluster
where we have literally nothing.

**P3 - national season pages:** `/sommerferien/d/<year>` etc. with
per-state date table (targets "sommerferien 2026" 93K + "herbstferien
<jahr>" and stops city pages soaking these queries at 0% CTR).

**P4 - CTR work:** school page titles/meta leading with next vacation
dates; FAQ blocks + FAQPage schema on state/season pages ("wann sind
sommerferien" 585 impr pos 8 across 180 URLs).

**P5 - authority (unchanged Phase 3):** DR 10 vs schulferien.org ~70s
stays the head-term ceiling. Data PR, embeddable widget, API developer
marketing. Note "ferien api" / "feiertage api" queries already bring
the /developers pages impressions - the API angle has organic demand.

### How to verify success

| Check | Baseline 2026-07-21 | Success looks like |
|---|---|---|
| "osterferien/weihnachtsferien/pfingstferien <state> <year>" positions | Not ranking (wrong slugs 302 away) | Corrected URLs indexed, climbing into top 20 by season peaks |
| "feiertage <state> <year>" | 314 queries pos 40-70 on wrong pages | Dedicated pages ranking; any top-20 appearance is progress |
| Evergreen state pages | Thüringen pos 24 on "osterferien thüringen 2026" | Several states in top 10-20 on season+state queries by Oct 2026 |
| Brückentage evergreen | 302 redirect | Real page, year queries consolidating onto it |
| DR trend | 10 (down from 15) | Stabilize, then climb with Phase 3 links |

## 2026-07-21: P1-P4 shipped (v4.33.0)

Implementation of the re-prioritized roadmap above, same day. All
changes test-covered (1,200 tests green, credo clean).

**P1 - season + bridge day URL structure:**

1. New `MehrSchulferien.Calendars.VacationSlug` maps DB slugs to the
   German compound URL slugs (ostern→osterferien,
   weihnachten→weihnachtsferien, pfingsten→pfingstferien,
   fruehjahr→fruehjahrsferien, himmelfahrt→himmelfahrtsferien). The
   correct slugs now RENDER; the old generated slugs (osternferien,
   weihnachtenferien, ...) 301 to them. Every link builder (state
   templates, components, handwritten images, next-vacation redirect,
   sitemap) emits the canonical slug. This also fixed the national
   season overview pages, whose rel=canonical pointed at 404 URLs
   (/osterferien declared canonical /osternferien).
2. Evergreen season-state pages: `/osterferien/<state>` etc. are real
   pages (current + next year, next-occurrence hero, FAQ + FAQPage/
   Event schema, self-canonical, sitemap 0.85) instead of 302s.
3. Evergreen Brückentage state pages: `/brueckentage/d/bundesland/
   <slug>` renders the dormant evergreen template again (current-year
   proposals + year links, proper canonical/OG meta, sitemap). Nav
   current-year tabs (both implementations) now funnel to the evergreen
   bridge day pages, mirroring the state pages.
4. Past-year season pages 301 to the evergreen season page (the
   /osternferien/hessen/2022 zombie class is gone). Year params are
   validated in the controller (router constraints are decorative).

**P2 - Feiertage page family** (new FeiertagController + templates):
`/feiertage/d` (evergreen national), `/feiertage/d/<year>` (per-holiday
rows with "bundesweit" vs state list), `/feiertage/d/bundesland/<slug>`
(evergreen, FAQPage schema with holiday counts) and `.../<year>`.
Past years 301 to the evergreen pages. All in the sitemap, plus a
fourth "Feiertage" nav dropdown (desktop + mobile, both nav
implementations) with cross-links to Brückentage and Schulferien.

**P3 - national season year pages:** `/sommerferien/<year>` etc. render
the all-states table for that year (self-canonical, ItemList schema,
past years 301 to `/sommerferien`). In the static sitemap for current +
next year. Targets "sommerferien 2026" (93K) and stops random city
pages from soaking those queries.

**P4 - CTR:**

- School page titles lead with the school name ("<Name>: Ferien & freie
  Tage 2026/2027") and the meta description leads with the next
  vacation dates ("Nächste Ferien: Herbstferien vom 23.10. bis
  03.11."). Navigational searchers finally get a reason to click.
- FAQPage schema added to the evergreen state pages (was only on year
  pages); the schema component now labels questions with each period's
  own year instead of the page year.

**Not shipped (P5, non-code):** data-driven PR, the embeddable widget
and API developer marketing remain open - they need editorial/outreach
work, not routes.

### How to verify success

Same checkpoints as above (Oct 2026, Jan 2027). Additionally check in
GSC after 2-4 weeks: the legacy season URLs report "Seite mit
Weiterleitung", the corrected slugs gather impressions, and
`/feiertage/` pages appear in the page report at all.
