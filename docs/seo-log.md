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
