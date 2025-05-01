# mehr-schulferien.de

This project is the 2020 (last update 2024) version of 
https://www.mehr-schulferien.de

The webpage provides information about school vacations and public holidays
in Germany.

# Developers

See the [contributing guide](https://github.com/mehr-schulferien-de/www.mehr-schulferien.de/blob/master/CONTRIBUTING.md)
for more information about setting up your development environment and opening pull
requests.

## Project Structure

The application follows a modular structure with clear separation of concerns:

### Core Domains

- **Locations** (`lib/mehr_schulferien/locations`): Manages geographic entities (countries, federal states, counties, cities, schools)
  - `Query`: Database queries for locations
  - `CRUD`: Create, read, update, delete operations
  - `Specialized`: Specialized operations like hierarchical lookups
  
- **Periods** (`lib/mehr_schulferien/periods`): Handles time periods such as holidays and vacations
  - `Query`: Database queries for periods
  - `DateOperations`: Date manipulation and filtering operations
  - `Grouping`: Functions for grouping and categorizing periods
  
- **Calendars** (`lib/mehr_schulferien/calendars`): Manages holiday/vacation types and religions
  - `ReligionOperations`: Operations for religions
  - `HolidayOperations`: Operations for holiday types
  
- **Maps** (`lib/mehr_schulferien/maps`): Handles address and zip code data

### Web Layer

- **Controllers** (`lib/mehr_schulferien_web/controllers`): HTTP request handlers
  - `Helpers`: Controller helper functions:
    - `PeriodHelpers`: Functions for handling periods in controllers
    - `LocationHelpers`: Functions for handling locations in controllers
    
- **Templates** (`lib/mehr_schulferien_web/templates`): HTML views
- **Views** (`lib/mehr_schulferien_web/views`): View helpers
- **Shared** (`lib/mehr_schulferien_web/shared`): Components shared across the application

### Utilities

- **Slugs** (`lib/mehr_schulferien/slugs.ex`): Slug generation for URLs

## Data Structure

The situation: We have countries, federal_states, counties, cities and schools.
They all have different possibilities to set vacation dates or public holidays.

We aim to be able to render all pages on the fly. So our main problem is to make it possible that we can read the needed data fast. That is the idea behind the data model.

### Locations

Locations are stored in a single table which contains countries, federal_states, counties, cities and schools. They are all linked to the parent_location, creating a hierarchical tree structure that allows us to navigate up the chain from a school to its city, county, federal state, and country.

Each location has exactly one type (country, federal_state, county, city, or school), which is controlled by boolean flags in the schema.

### Maps

A city can have multiple zip_codes and one zip_code can belong to multiple cities.
Therefore we have a zip_code_mapping table which connects them to the location
of a city.

### Calendars

The calendars domain contains:
- **Religions**: Stores available religions
- **HolidayOrVacationTypes**: Stores types of different holidays and vacations

### Periods

Periods store the actual holiday and vacation dates. Each period is associated with:
- A location (where it applies)
- A holiday or vacation type
- Optional religion (for religious holidays)
- Start and end dates
- Various flags that determine visibility and behavior

# CSS Framework Migration

The application is in the process of migrating from Bootstrap to Tailwind CSS. During this transition period, both frameworks are supported:

- Bootstrap is used by default (legacy system)
- Tailwind CSS can be enabled for specific views

## How to Switch Between CSS Frameworks

### Global Configuration

The default CSS framework is configured in `config/config.exs`:

```elixir
config :mehr_schulferien,
  ecto_repos: [MehrSchulferien.Repo],
  # Set to :bootstrap for legacy CSS or :tailwind for new CSS implementation
  css_framework: :bootstrap
```

To change the default for the entire application, update the `css_framework` value to either `:bootstrap` or `:tailwind`.

### Per-View Configuration

You can override the default CSS framework for individual views by passing the `css_framework` option to the render function:

```elixir
# Use Tailwind CSS for this view
def developers(conn, _params) do
  render(conn, "developers.html", css_framework: :tailwind)
end

# Use Bootstrap CSS for this view
def some_action(conn, _params) do
  render(conn, "some_template.html", css_framework: :bootstrap)
end
```

### Implementation Details

The CSS framework is determined by a helper function in `MehrSchulferienWeb.LayoutView`:

```elixir
def use_bootstrap?(_conn, assigns) do
  cond do
    # Check if the current view has explicitly specified which CSS framework to use
    Map.has_key?(assigns, :css_framework) ->
      assigns.css_framework == :bootstrap

    # Fall back to application config
    Application.get_env(:mehr_schulferien, :css_framework) ->
      Application.get_env(:mehr_schulferien, :css_framework) == :bootstrap

    # Default to Bootstrap during the migration period
    true ->
      true
  end
end
```

The layout file checks this function to determine which CSS to include:

```elixir
<%= if use_bootstrap?(@conn, assigns) do %>
  <style>
  <%= render(MehrSchulferienWeb.LayoutView, "_purified_css.html") %>
  </style>
<% else %>
  <link rel="stylesheet" href="<%= Routes.static_path(@conn, "/assets/app.css") %>"/>
<% end %>
```

# Development Setup

To start your Phoenix server:

  * Clone the project
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `priv/repo/reset-db.sh`
  * Start Phoenix endpoint with `iex -S mix phx.server`

## Environment Setup

This project uses [mise](https://mise.jdx.dev/) for managing language versions. The required versions are specified in `.mise.toml`.

If you have mise installed, it will automatically use the correct versions of:
- Elixir
- Erlang
- Node.js

To install mise, follow the instructions at [mise.jdx.dev](https://mise.jdx.dev/).

Open [`localhost:4000`](http://localhost:4000) in your browser.

Open an issue in case you run into any problems.
