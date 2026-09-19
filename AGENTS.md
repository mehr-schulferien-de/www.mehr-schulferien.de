# Project rules

- Keep `mix precommit` available and aligned with CI (format check, warnings-as-errors compilation, strict Credo, tests), with `def cli, do: [preferred_envs: [precommit: :test]]` on Elixir 1.19 instead of deprecated `preferred_cli_env`, so the deploy gate runs against the test database without warnings. Check formatter idempotency; if HEEx repeatedly adds whitespace around inline interpolation, render the complete phrase as one string expression.

- Keep aliases alphabetically ordered (including grouped aliases) and run `mix credo --strict` on new modules; formatting alone does not enforce alias order.

- For calendar answers, sort dates chronologically with `Enum.sort_by(..., Date)`, not by struct order. Do not assume display-priority query results are chronological. Regression tests must span different months and years. Derive past/present wording from the supplied page date, and prefer active holidays over recently completed ones when answering when school resumes.
- Match the advertised calendar range in both HTML and JSON-LD: full-year overviews must include autumn and Christmas, annual totals must clip periods at year boundaries, and next-event answers must use the page's supplied date.
- When testing JSON-LD with Floki, extract script content with `Floki.text(script, js: true)` and decode it with Jason before asserting semantic values. Default `Floki.text/1` omits scripts and can produce a misleading parser failure.
- For visible-copy assertions, parse HTML and normalize whitespace before comparing phrases; HEEx formatting can add line breaks without changing rendered copy. Embedded widgets must use `nofollow` on automatically distributed source links; additional editorial attribution must remain optional.
