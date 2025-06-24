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

The application uses **Tailwind CSS** as the primary styling framework. Bootstrap is legacy and should NOT be used for any new development.

- **IMPORTANT**: Always use Tailwind CSS classes for styling. Never use Bootstrap classes (e.g., `container`, `row`, `col-*`, `btn`, `form-control`, etc.)
- **StyleConfig** (`lib/mehr_schulferien/style_config.ex`): Manages consistent colors/styles
- **Framework Selection**: Configurable per-view or globally via `config/config.exs` 
- **Day Types**: Standardized styling for holidays, vacations, weekends, and bridge days

## Development Guidelines

### CRITICAL CODE QUALITY REQUIREMENTS - MUST FOLLOW
**⚠️ IMPORTANT: These are MANDATORY steps that MUST be completed after ANY code changes:**

1. **RUN TESTS FIRST**: `mix test` - ALL tests MUST pass before any work is considered complete
2. **FIX ALL WARNINGS**: `mix compile --warnings-as-errors` - NO warnings are acceptable
3. **FORMAT CODE**: `mix format` - Code MUST be properly formatted

**NEVER commit or consider work done without completing ALL three steps above.**

### Additional Requirements
- Pre-commit hooks enforce: tests, formatting, compilation, and various file checks
- Use simple solutions with onboard tools/packages when possible
- Focus only on assigned tasks (DRY principle, but avoid scope creep)

### Development Best Practices
- **Always write a test before starting to refactor code**

### Styling Guidelines
- **ALWAYS use Tailwind CSS** for all styling needs
- **NEVER use Bootstrap classes** - the project has migrated away from Bootstrap
- Common Tailwind patterns in this project:
  - Layout: `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8`
  - Cards: `bg-white shadow-sm rounded-lg`
  - Forms: `border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500`
  - Buttons: `px-6 py-2 bg-blue-600 text-white font-medium rounded-md hover:bg-blue-700`
  - Tables: `min-w-full divide-y divide-gray-200`

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
- **Responsive design** with Bootstrap/Tailwind CSS flexibility

## Repository Guidelines

### Git and GitHub Workflow
- **Don't git push anything to GitHub without the user asking for it.**