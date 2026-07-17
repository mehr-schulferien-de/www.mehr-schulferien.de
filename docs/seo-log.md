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

- Main navigation still links year pages, not the evergreen pages.
- If evergreen pages gain traction, consider consolidating year pages
  into them via 301, as was done for cities (the proven pattern here).
- No GA4 on the site; add gtag.js when a measurement ID is available.
