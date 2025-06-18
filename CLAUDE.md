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

The application supports both Bootstrap (legacy) and Tailwind CSS through a centralized style configuration system:

- **StyleConfig** (`lib/mehr_schulferien/style_config.ex`): Manages consistent colors/styles across frameworks
- **Framework Selection**: Configurable per-view or globally via `config/config.exs`
- **Day Types**: Standardized styling for holidays, vacations, weekends, and bridge days

## Development Guidelines

### Code Quality Requirements
- Always run `mix test` and fix all failures/warnings before considering work complete
- Run `mix format` after making changes
- Pre-commit hooks enforce: tests, formatting, compilation, and various file checks
- Use simple solutions with onboard tools/packages when possible
- Focus only on assigned tasks (DRY principle, but avoid scope creep)

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