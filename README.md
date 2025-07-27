# mehr-schulferien.de

This project is the 2020 (last update 2024) version of 
https://www.mehr-schulferien.de

The webpage provides information about school vacations and public holidays
in Germany.

# Developers

See the [contributing guide](https://github.com/mehr-schulferien-de/www.mehr-schulferien.de/blob/master/CONTRIBUTING.md)
for more information about setting up your development environment and opening pull
requests.

## Required Dependencies

### LaTeX Packages for PDF Generation

The application uses LaTeX to generate PDF documents (excuse letters). The following packages need to be installed:

#### macOS
```bash
# Install MacTeX (if not already installed)
brew install --cask mactex

# Install required LaTeX packages
sudo tlmgr install pst-barcode
```

#### Ubuntu/Debian
```bash
# Install TeX Live and required packages
sudo apt-get install texlive-latex-base texlive-latex-extra texlive-latex-recommended
sudo apt-get install texlive-pstricks

# Install ImageMagick for image processing (used by Mogrify)
sudo apt-get install imagemagick

# Install system dependencies for Resvg (SVG rendering)
sudo apt-get install libfontconfig1-dev

# Install WebP tools for WebP format support
sudo apt-get install webp

# Install Comic Neue font (used in image generation)
sudo apt-get install fonts-comic-neue
```

#### Windows
1. Install MiKTeX from https://miktex.org/download
2. Open MiKTeX Console
3. Go to Packages
4. Search for and install `pst-barcode`

## Documentation

- [URL Parameters](docs/url_parameters.md) - Information about available URL parameters for customizing views
- [API v2.1 Documentation](docs/api_v2.1.md) - REST API documentation with improved structure (recommended)
- [API v2.0 Documentation](docs/api_v2.md) - Legacy REST API documentation

## Features

### School Data Enrichment
The wiki system now includes automated data enrichment capabilities:
- **Search Engine Integration**: Automatically fetch school information (homepage, phone, social media) from search results
- **Selective Updates**: Choose which fields to update from the enriched data
- **Data Source Tracking**: Shows where data comes from and when it was last refreshed

### Improved Bewegliche Ferientage Management
Enhanced input methods for school holidays:
- **Flexible Date Input**: Support for single dates, date ranges, and multiple dates
  - Single date: `16.02.2026`
  - Date range: `16.-20.02.2026`
  - Multiple dates: `16.02.2026, 18.03.2026`
- **Bulk Operations**: Add multiple holidays at once
- **Copy & Paste Support**: Easy input from external sources

## Project Structure

The application follows a modular structure with clear separation of concerns:

### Core Domains

- **Locations** (`lib/mehr_schulferien/locations`): Manages geographic entities (countries, federal states, counties, cities, schools)
- **Periods** (`lib/mehr_schulferien/periods`): Handles time periods such as holidays and vacations
- **Calendars** (`lib/mehr_schulferien/calendars`): Manages holiday/vacation types and religions
- **Maps** (`lib/mehr_schulferien/maps`): Handles address and zip code data

### Web Layer

- **Controllers** (`lib/mehr_schulferien_web/controllers`): HTTP request handlers
- **Templates** (`lib/mehr_schulferien_web/templates`): HTML views
- **Views** (`lib/mehr_schulferien_web/views`): View helpers
- **Shared** (`lib/mehr_schulferien_web/shared`): Components shared across the application

### Utilities

- **Slugs** (`lib/mehr_schulferien/slugs.ex`): Slug generation for URLs
- **StyleConfig** (`lib/mehr_schulferien/style_config.ex`): Centralized color and style configuration for both Bootstrap and Tailwind CSS

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

# Styling and CSS Framework Configuration

## Centralized Style Configuration

The application uses a centralized style configuration module (`MehrSchulferien.StyleConfig`) to manage consistent colors and styles for different types of days (holidays, vacations, weekends, bridge days) with the Tailwind CSS framework.

### Using StyleConfig

```elixir
# Get a Bootstrap class for holidays
MehrSchulferien.StyleConfig.get_class(:holiday, :bootstrap)  # Returns "danger"

# Get a Tailwind class for vacations (normal intensity)
MehrSchulferien.StyleConfig.get_class(:vacation, :tailwind)  # Returns "bg-green-600"

# Get a light Tailwind class for weekends
MehrSchulferien.StyleConfig.get_class(:weekend, :tailwind, true)  # Returns "bg-gray-100"

# Helper functions for determining the day type
MehrSchulferien.StyleConfig.html_class_to_day_type("success")  # Returns :vacation
```

### Day Types

The system uses the following standard day types with their associated colors:

| Day Type    | Description | Bootstrap Class | Tailwind Class | Light Tailwind |
|-------------|-------------|-----------------|----------------|----------------|
| `:holiday`  | Feiertage   | `danger` (red)  | `bg-blue-600`  | `bg-blue-100`  |
| `:vacation` | Schulferien | `success` (green)| `bg-green-600` | `bg-green-100` |
| `:weekend`  | Wochenenden | `active` (gray) | `bg-gray-100`  | `bg-gray-100`  |
| `:bridge_day`| Brückentage | `warning` (yellow)| `bg-yellow-500`| `bg-yellow-100`|

# Development Setup

To start your Phoenix server:

  * Clone the project
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `priv/repo/reset-db.sh`
  * Start Phoenix endpoint with `iex -S mix phx.server`

Open [`localhost:4000`](http://localhost:4000) in your browser.

Open an issue in case you run into any problems.

## Environment Variables

The following environment variables can be configured:

### SerpApi Search (Optional)

If you want to use the school search functionality with SerpApi (supports multiple search engines):

```bash
export SERPAPI_API_KEY="your_serpapi_key_here"
```

To get an API key:
1. Visit https://serpapi.com
2. Sign up for an account
3. Copy your API key from the dashboard

The search functionality is used by the `mix search_school` task to enrich school data with:
- Homepage URLs
- Phone numbers
- Social media links
- School descriptions

If the API key is not set, the search functionality will return an error message.

## Database Restore in Development

Get a current backup file and replace the following:
s/mehr_schulferien_2020_prod/mehr_schulferien_dev/g
s/mehrschul2020/postgres/g

And add a 
DROP DATABASE mehr_schulferien_dev;

psql -U postgres -f mehr_schulferien_2020_prod_2025-07-26_06h25m.Samstag.sql

