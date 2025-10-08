# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Phoenix/Elixir web application for "mehr-schulferien.de" - a German website providing information about school vacations and public holidays. The application serves vacation and holiday data for locations across Germany through a hierarchical structure of countries, federal states, counties, cities, and schools.

## Development Setup

### Prerequisites
- Erlang 27.3.4
- Elixir 1.18.4-otp-27 
- Node.js > 6.8.0
- PostgreSQL
- LaTeX packages for PDF generation (see README.md for platform-specific instructions)

### Tool Management
Use `mise` (not `asdf`) to manage Elixir, Erlang, and Node.js versions as specified in `.tool-versions`.

### Essential Commands

```bash
# Initial setup
mix deps.get
mix ecto.setup
mix assets.setup
mix assets.build

# Database operations
mix ecto.reset                    # Reset database completely
mix ecto.create                   # Create database
mix ecto.migrate                  # Run migrations
mix run priv/repo/seeds.exs       # Seed database

# Development server
iex -S mix phx.server            # Start interactive server
mix phx.server                   # Start server (non-interactive)

# Testing
mix test                         # Run all tests
mix test --warnings-as-errors    # Run tests with warnings as errors

# Code formatting and quality
mix format                       # Format code
mix format --check-formatted     # Check formatting
mix compile --warnings-as-errors # Compile with warnings as errors

# Asset management
mix assets.setup                 # Install asset dependencies
mix assets.build                 # Build assets for development
mix assets.deploy                # Build and optimize assets for production
```

## Architecture

### Core Domain Structure

The application follows a modular Phoenix architecture with clear domain separation:

- **Locations** (`lib/mehr_schulferien/locations/`): Geographic hierarchy (countries → federal states → counties → cities → schools)
- **Periods** (`lib/mehr_schulferien/periods/`): Holiday and vacation time periods
- **Calendars** (`lib/mehr_schulferien/calendars/`): Holiday/vacation types and religions
- **Maps** (`lib/mehr_schulferien/maps/`): Address and zip code mapping

### Data Model

All locations (countries, federal states, counties, cities, schools) are stored in a single `locations` table with a hierarchical parent-child relationship. This enables efficient queries up the location chain.

### CSS Framework Architecture

The application uses **Tailwind CSS** as the styling framework with a unified design system.

- **IMPORTANT**: Always use Tailwind CSS classes for styling
- **Design Tokens** (`lib/mehr_schulferien_web/components/shared/design_tokens.ex`): Central design system
- **Shared Components** (`lib/mehr_schulferien_web/components/shared/`): Reusable UI components
- **StyleConfig** (`lib/mehr_schulferien/style_config.ex`): Manages day type colors/styles
- **Day Types**: Standardized styling for holidays, vacations, weekends, and bridge days

### Layout System

The application uses a unified layout system:

- **Layout Template**: All pages use `app_tailwind_full.html.heex` with full navigation and footer
- **DEPRECATED**: The `css_framework` parameter in controllers is deprecated and no longer needed
- **Migration Complete**: All pages have been migrated to the modern Tailwind layout
- **DO NOT** use `css_framework: :tailwind_new` in new code - it's no longer necessary

## Development Guidelines

### CRITICAL CODE QUALITY REQUIREMENTS - MUST FOLLOW
**⚠️ IMPORTANT: Code quality is automatically enforced via hooks:**

The project uses Claude Code hooks that automatically run after each response:
- **Format**: `mix format` ensures code is properly formatted
- **Test**: `mix test` runs the full test suite
- **Compile**: `mix compile --warnings-as-errors` catches warnings during editing

**Your responsibilities:**
1. **FIX ALL TEST FAILURES**: When hooks report test failures, update tests if UI changes broke assertions (e.g., changed text, CSS classes, HTML structure)
2. **FIX ALL WARNINGS**: When hooks report compilation warnings, address them immediately
3. **VERIFY TEST OUTPUT QUALITY**: Tests must run with CLEAN output (only dots, no warnings/errors)
4. **UI CHANGES REQUIRE SPECIAL ATTENTION**: When modifying templates, LiveView render functions, or CSS classes, anticipate which tests need updating

### TEST QUALITY STANDARDS - MANDATORY
**🧪 IMPORTANT: Maintain clean, reliable tests at all times:**

#### What Makes Tests "Clean"
- **NO debug output**: Remove all `IO.puts`, `IO.inspect`, `dbg()` from tests
- **NO skipped tests**: Either fix or remove `@tag :skip` tests
- **NO placeholder tests**: Never use `assert true` - write real assertions
- **NO warnings/errors in output**: Test output should be dots only (`.` for pass, `*` for pending)
- **NO flaky tests**: Tests must pass consistently, not randomly

#### When Working With Tests, ALWAYS:
1. **Check test output cleanliness**: Run `mix test 2>&1 | grep -E "warning|error"` to find issues
2. **Remove debug statements**: Search for `IO.puts|IO.inspect|dbg` in test files
3. **Fix or remove skipped tests**: Search for `@tag :skip` and handle them
4. **Suppress expected warnings in test env**: Use `Application.get_env(:mehr_schulferien, :env) != :test`
5. **Handle race conditions**: Use proper test setup/teardown, avoid shared state

#### Common Test Issues to Fix:
- **Nominatim warnings**: Suppress geocoding warnings for fake test addresses
- **Stale entry errors**: Handle Ecto.StaleEntryError gracefully in concurrent tests
- **Database ownership errors**: Ensure proper Ecto.Sandbox usage
- **Debug output**: Remove all IO operations that pollute test output
- **Logger output**: Set `config :logger, level: :error` in `config/test.exs`

#### Test Quality Checklist (Run Before Every Commit):
```bash
# 1. Check for clean output
mix test 2>&1 | tail -5  # Should show only "X tests, 0 failures"

# 2. Check for skipped tests
grep -r "@tag :skip" test/  # Should return nothing

# 3. Check for debug output
grep -r "IO\.\(puts\|inspect\)" test/  # Should return nothing

# 4. Check for placeholder tests
grep -r "assert true" test/  # Should return nothing

# 5. Run full test suite
mix test  # Output should be only dots, no text
```

### Additional Requirements
- Claude Code hooks automatically enforce: tests, formatting, compilation after each response
- Git pre-commit hooks enforce: tests, formatting, compilation, and various file checks
- Use simple solutions with onboard tools/packages when possible
- Focus only on assigned tasks (DRY principle, but avoid scope creep)

### Development Best Practices
- **Always write a test before starting to refactor code**

### Styling Guidelines
- **ALWAYS use Tailwind CSS** for all styling needs
- **Use shared components** from `lib/mehr_schulferien_web/components/shared/` for consistency:
  - Typography: `<.heading>`, `<.text>`, `<.link>`
  - Layout: `<.grid>`, `<.card_grid>`, `<.container>`, `<.stack>`
  - UI Elements: `<.card>`, `<.button>`, `<.badge>`, `<.alert>`
  - Tables: `<.table>`, `<.thead>`, `<.tbody>`, `<.tr>`, `<.td>`
- Common patterns are defined in the design token system
- **List formatting**: For HTML lists (`<ul>`, `<ol>`), use proper Tailwind classes:
  - Use `list-disc` or `list-decimal` for bullet/number styles
  - Use `ml-5` or similar margin for proper indentation
  - Avoid manual bullet points (•) in list items
  - This ensures proper text wrapping where continuation lines align with text, not bullets

### Testing Strategy
- System tests for full user workflows
- Unit tests for individual modules
- Component tests for LiveView components
- Use ExMachina factory for test data generation

### File Structure Patterns
- Controllers handle HTTP requests and delegate to domain modules
- Views contain presentation logic and helpers
- Templates use `.html.heex` for LiveView components, `.html.eex` for standard templates
- Shared components live in `lib/mehr_schulferien_web/components/`
- Domain logic stays in `lib/mehr_schulferien/` modules

## Key Features

- **Multi-language support** via Gettext
- **PDF generation** for excuse letters using LaTeX
- **iCal export** for calendar integration
- **API endpoints** (v2) for programmatic access
- **Sitemap generation** for SEO
- **LiveView** for interactive components
- **Responsive design** with Tailwind CSS

## Phoenix 1.8 Migration Status

**✅ COMPLETED**: This project has been successfully upgraded from Phoenix 1.7.21 to Phoenix 1.8.0.

### Migration Details:
- **HTML Modules**: All View modules have been migrated to format-specific modules (HTML, JSON, ICS, XML)
- **Controller Configuration**: Updated to use `:formats` and `:layouts` options
- **Test Dependencies**: Added `lazy_html` for LiveView tests
- **All tests passing**: 707 tests, 0 failures

### Module Structure:
- HTML modules: `lib/mehr_schulferien_web/controllers/*_html.ex`
- JSON modules: `lib/mehr_schulferien_web/controllers/api/v2/*_json.ex`
- ICS modules: `lib/mehr_schulferien_web/controllers/api/v2/*_ics.ex`
- XML modules: `lib/mehr_schulferien_web/controllers/*_xml.ex`

## Phoenix Verified Routes (~p sigil)

The project has been fully migrated to Phoenix verified routes and exclusively uses the `~p` sigil for all routing.

### Implementation
1. **Setup** - Verified routes are configured in:
   - `lib/mehr_schulferien_web.ex` - Added `use Phoenix.VerifiedRoutes` to controller, view, and view_helpers macros
   - Components that need routing include `use Phoenix.VerifiedRoutes, endpoint: MehrSchulferienWeb.Endpoint, router: MehrSchulferienWeb.Router`

2. **Usage** - All routes use the ~p sigil pattern:
   ```elixir
   # Paths
   ~p"/#{@vacation_type}/#{state_slug}/#{@year}"
   ~p"/ferien/#{@country.slug}/bundesland/#{@federal_state.slug}"
   
   # URLs (for meta tags, redirects, etc.)
   url(~p"/#{@vacation_type}/#{state_slug}/#{@year}")
   
   # Static assets
   static_path(@conn, "/assets/app.css")
   static_url(@conn, "/images/file.png")
   ```

3. **Migration Complete**:
   - ✅ **All controllers migrated** (8 files): redirect, vacation, wiki, federal_state, bridge_day, city, school
   - ✅ **All templates migrated** (45+ files): vacation, city, country, federal_state, school, bridge_day, page, partial, wiki, layout
   - ✅ **All LiveView files migrated** (4 files): entschuldigung, beurlaubung, sportbefreiung, wiki_school_new
   - ✅ **All components migrated**: vacation_type_components and other shared components
   - ✅ **Legacy RouteHelpers module removed**
   - ✅ **All Routes aliases removed**

4. **Benefits**:
   - **Compile-time verification**: Routes are checked at compile time, preventing broken links
   - **Better performance**: No runtime route generation overhead  
   - **Type safety**: Parameters are validated against route definitions
   - **Cleaner code**: More concise syntax than the old Routes helpers

## Repository Guidelines

## Memories

- Always remember the sitemap.xml file to be up to date if URLs are added, removed or changed.
- Tests may fail due to cache issues - use `MehrSchulferien.Cache.clear_query_cache()` in tests when needed.
- Claude Code hooks automatically run `mix format` and `mix test` after each response, ensuring code quality.
<!-- usage-rules-start -->
<!-- usage-rules-header -->
# Usage Rules

**IMPORTANT**: Consult these usage rules early and often when working with the packages listed below. 
Before attempting to use any of these packages or to discover if you should use them, review their 
usage rules to understand the correct patterns, conventions, and best practices.
<!-- usage-rules-header-end -->

<!-- igniter-start -->
## igniter usage
_A code generation and project patching framework_

[igniter usage rules](deps/igniter/usage-rules.md)
<!-- igniter-end -->
<!-- usage_rules-start -->
## usage_rules usage
_A dev tool for Elixir projects to gather LLM usage rules from dependencies_

[usage_rules usage rules](deps/usage_rules/usage-rules.md)
<!-- usage_rules-end -->
<!-- usage_rules:elixir-start -->
## usage_rules:elixir usage
[usage_rules:elixir usage rules](deps/usage_rules/usage-rules/elixir.md)
<!-- usage_rules:elixir-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage
[usage_rules:otp usage rules](deps/usage_rules/usage-rules/otp.md)
<!-- usage_rules:otp-end -->
<!-- claude-start -->
## claude usage
_Batteries-included Claude Code integration for Elixir projects_

[claude usage rules](deps/claude/usage-rules.md)
<!-- claude-end -->
<!-- claude:subagents-start -->
## claude:subagents usage
[claude:subagents usage rules](deps/claude/usage-rules/subagents.md)
<!-- claude:subagents-end -->
<!-- phoenix:ecto-start -->
## phoenix:ecto usage
[phoenix:ecto usage rules](deps/phoenix/usage-rules/ecto.md)
<!-- phoenix:ecto-end -->
<!-- phoenix:elixir-start -->
## phoenix:elixir usage
[phoenix:elixir usage rules](deps/phoenix/usage-rules/elixir.md)
<!-- phoenix:elixir-end -->
<!-- phoenix:html-start -->
## phoenix:html usage
[phoenix:html usage rules](deps/phoenix/usage-rules/html.md)
<!-- phoenix:html-end -->
<!-- phoenix:liveview-start -->
## phoenix:liveview usage
[phoenix:liveview usage rules](deps/phoenix/usage-rules/liveview.md)
<!-- phoenix:liveview-end -->
<!-- phoenix:phoenix-start -->
## phoenix:phoenix usage
[phoenix:phoenix usage rules](deps/phoenix/usage-rules/phoenix.md)
<!-- phoenix:phoenix-end -->
<!-- usage-rules-end -->

## Test Maintenance Protocol

### When Asked About Tests or Test Issues:
1. **ALWAYS check test output quality first** - Run `mix test` and look for any non-dot output
2. **Identify ALL issues** - Don't just fix the obvious one, scan for:
   - Warnings/errors in output
   - Skipped tests
   - Debug statements
   - Flaky/intermittent failures
3. **Fix systematically** - Address root causes, not symptoms:
   - Suppress logging in test environment properly
   - Handle race conditions with proper test isolation
   - Remove or fix skipped tests, never leave them
4. **Verify the fix** - Run tests multiple times to ensure consistency

### Proactive Test Maintenance:
- **After any code change**: Check that test output remains clean
- **When adding new features**: Ensure new tests follow clean output standards
- **During refactoring**: Remove any debug code before committing
- **Before suggesting commits**: ALWAYS run the test quality checklist

### Red Flags That Require Immediate Action:
- Any `IO.puts`, `IO.inspect`, or `dbg()` in test files
- Tests with `@tag :skip` or `@moduletag :skip`
- Tests that just `assert true` (placeholder tests)
- Any warning or error messages during test runs
- Tests that sometimes pass and sometimes fail (flaky tests)

## Git Workflow and Interactions Memories

- You are allowed to git commit and git push code but ask the user first or wait for the user to tell you to do it.
- **IMPORTANT**: Git pre-commit hooks automatically run the test quality checklist before commits
