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

## Development Guidelines

### CRITICAL CODE QUALITY REQUIREMENTS - MUST FOLLOW
**⚠️ IMPORTANT: These are MANDATORY steps that MUST be completed after ANY code changes:**

1. **RUN TESTS FIRST**: `mix test` - ALL tests MUST pass before any work is considered complete
2. **FIX ALL WARNINGS**: `mix compile --warnings-as-errors` - NO warnings are acceptable
3. **FORMAT CODE**: `mix format` - Code MUST be properly formatted
4. **FIX TESTS BEFORE GIT COMMIT**: `mix test` - All tests must be green before you can `git commit` anything.

**NEVER commit or consider work done without completing ALL three steps above.**

### Additional Requirements
- Pre-commit hooks enforce: tests, formatting, compilation, and various file checks
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

## Phoenix Verified Routes (~p sigil)

The project has been fully migrated to Phoenix verified routes (Phoenix 1.7.21+) and exclusively uses the `~p` sigil for all routing.

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
<!-- usage-rules-start -->
<!-- usage-rules-header -->
# Usage Rules

**IMPORTANT**: Consult these usage rules early and often when working with the packages listed below. 
Before attempting to use any of these packages or to discover if you should use them, review their 
usage rules to understand the correct patterns, conventions, and best practices.
<!-- usage-rules-header-end -->

<!-- igniter-start -->
## igniter usage
_A code generation and project patching framework
_

[igniter usage rules](deps/igniter/usage-rules.md)
<!-- igniter-end -->
<!-- usage_rules-start -->
## usage_rules usage
_A dev tool for Elixir projects to gather LLM usage rules from dependencies
_

## Using Usage Rules

Many packages have usage rules, which you should *thoroughly* consult before taking any
action. These usage rules contain guidelines and rules *directly from the package authors*.
They are your best source of knowledge for making decisions.

## Modules & functions in the current app and dependencies

When looking for docs for modules & functions that are dependencies of the current project,
or for Elixir itself, use `mix usage_rules.docs`

```
# Search a whole module
mix usage_rules.docs Enum

# Search a specific function
mix usage_rules.docs Enum.zip

# Search a specific function & arity
mix usage_rules.docs Enum.zip/1
```


## Searching Documentation

You should also consult the documentation of any tools you are using, early and often. The best 
way to accomplish this is to use the `usage_rules.search_docs` mix task. Once you have
found what you are looking for, use the links in the search results to get more detail. For example:

```
# Search docs for all packages in the current application, including Elixir
mix usage_rules.search_docs Enum.zip

# Search docs for specific packages
mix usage_rules.search_docs Req.get -p req

# Search docs for multi-word queries
mix usage_rules.search_docs "making requests" -p req

# Search only in titles (useful for finding specific functions/modules)
mix usage_rules.search_docs "Enum.zip" --query-by title
```


<!-- usage_rules-end -->
<!-- usage_rules:elixir-start -->
## usage_rules:elixir usage
# Elixir Core Usage Rules

## Pattern Matching
- Use pattern matching over conditional logic when possible
- Prefer to match on function heads instead of using `if`/`else` or `case` in function bodies

## Error Handling
- Use `{:ok, result}` and `{:error, reason}` tuples for operations that can fail
- Avoid raising exceptions for control flow
- Use `with` for chaining operations that return `{:ok, _}` or `{:error, _}`

## Common Mistakes to Avoid
- Elixir has no `return` statement, nor early returns. The last expression in a block is always returned.
- Don't use `Enum` functions on large collections when `Stream` is more appropriate
- Avoid nested `case` statements - refactor to a single `case`, `with` or separate functions
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Lists and enumerables cannot be indexed with brackets. Use pattern matching or `Enum` functions
- Prefer `Enum` functions like `Enum.reduce` over recursion
- When recursion is necessary, prefer to use pattern matching in function heads for base case detection
- Using the process dictionary is typically a sign of unidiomatic code
- Only use macros if explicitly requested
- There are many useful standard library functions, prefer to use them where possible

## Function Design
- Use guard clauses: `when is_binary(name) and byte_size(name) > 0`
- Prefer multiple function clauses over complex conditional logic
- Name functions descriptively: `calculate_total_price/2` not `calc/2`
- Predicate function names should not start with `is` and should end in a question mark. 
- Names like `is_thing` should be reserved for guards

## Data Structures
- Use structs over maps when the shape is known: `defstruct [:name, :age]`
- Prefer keyword lists for options: `[timeout: 5000, retries: 3]`
- Use maps for dynamic key-value data
- Prefer to prepend to lists `[new | list]` not `list ++ [new]`

## Mix Tasks

- Use `mix help` to list available mix tasks
- Use `mix help task_name` to get docs for an individual task
- Read the docs and options fully before using tasks

## Testing
- Run tests in a specific file with `mix test test/my_test.exs` and a specific test with the line number `mix test path/to/test.exs:123`
- Limit the number of failed tests with `mix test --max-failures n`
- Use `@tag` to tag specific tests, and `mix test --only tag` to run only those tests
- Use `assert_raise` for testing expected exceptions: `assert_raise ArgumentError, fn -> invalid_function() end`
- Use `mix help test` to for full documentation on running tests

## Debugging

- Use `dbg/1` to print values while debugging. This will display the formatted value and other relevant information in the console.

<!-- usage_rules:elixir-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage
# OTP Usage Rules

## GenServer Best Practices
- Keep state simple and serializable
- Handle all expected messages explicitly
- Use `handle_continue/2` for post-init work
- Implement proper cleanup in `terminate/2` when necessary

## Process Communication
- Use `GenServer.call/3` for synchronous requests expecting replies
- Use `GenServer.cast/2` for fire-and-forget messages.
- When in doubt, us `call` over `cast`, to ensure back-pressure
- Set appropriate timeouts for `call/3` operations

## Fault Tolerance
- Set up processes such that they can handle crashing and being restarted by supervisors
- Use `:max_restarts` and `:max_seconds` to prevent restart loops

## Task and Async
- Use `Task.Supervisor` for better fault tolerance
- Handle task failures with `Task.yield/2` or `Task.shutdown/2`
- Set appropriate task timeouts
- Use `Task.async_stream/3` for concurrent enumeration with back-pressure

<!-- usage_rules:otp-end -->
<!-- usage-rules-end -->

## Git Workflow and Interactions Memories

- You are allowed to git commit and git push code but ask the user first or wait for the user to tell you to do it.