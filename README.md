# mehr-schulferien.de

The webpage provides information about school vacations and public holidays in Germany. 

Production: https://www.mehr-schulferien.de

## Quick Start

```bash
# Clone the repository
git clone https://github.com/mehr-schulferien-de/www.mehr-schulferien.de.git
cd www.mehr-schulferien.de

# Install dependencies
mix deps.get
mix ecto.setup

# Start the development server
iex -S mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) in your browser.

## System Requirements

### Required Dependencies

#### LaTeX for PDF Generation

The application generates PDF documents (excuse letters) using LaTeX.

**macOS:**
```bash
brew install --cask mactex
sudo tlmgr install pst-barcode
```

**Ubuntu/Debian:**
```bash
sudo apt-get install texlive-latex-base texlive-latex-extra texlive-latex-recommended texlive-pstricks
sudo apt-get install imagemagick libfontconfig1-dev webp fonts-comic-neue
```

**Windows:**
1. Install [MiKTeX](https://miktex.org/download)
2. Install `pst-barcode` package via MiKTeX Console

## Documentation

- [URL Parameters](docs/url_parameters.md) - Information about available URL parameters for customizing views
- [API v2.1 Documentation](docs/api_v2.1.md) - REST API documentation with improved structure (recommended)
- [API v2.0 Documentation](docs/api_v2.md) - Legacy REST API documentation

## Key Features

- **Multi-language support** via Gettext
- **PDF generation** for excuse letters (Entschuldigung/Beurlaubung)
- **iCal export** for calendar integration
- **REST API** (v2.1) for programmatic access
- **Wiki system** for collaborative data management with rollback support
- **School data enrichment** via search engine integration
- **Flexible holiday management** with bulk operations and date ranges
- **School quarantine system** for spam prevention (see below)
- **Responsive design** with Tailwind CSS
- **LiveView** for interactive components

## School Quarantine System

The application includes a quarantine system for schools to combat spam. Quarantined schools:
- Return **423 Locked** HTTP status with an explanation page
- Are excluded from all queries (search, nearby schools, sitemap, API, etc.)
- Can be managed via mix task

### Mix Task Usage

```bash
# Quarantine a school
mix school_quarantine --quarantine 12345-gymnasium-musterstadt

# Remove quarantine from a school
mix school_quarantine --unquarantine 12345-gymnasium-musterstadt

# List all quarantined schools
mix school_quarantine --list

# Check status of a specific school
mix school_quarantine --status 12345-gymnasium-musterstadt
```

### Programmatic Access

```elixir
# Quarantine a school (uses PaperTrail for audit logging)
{:ok, _} = MehrSchulferien.Locations.quarantine_school(school)

# Remove quarantine
{:ok, _} = MehrSchulferien.Locations.unquarantine_school(school)

# Check if school is quarantined
MehrSchulferien.Locations.school_quarantined?(school)

# List all quarantined schools
MehrSchulferien.Locations.list_quarantined_schools()

# Get school including quarantined (for admin purposes)
MehrSchulferien.Locations.get_school_by_slug_including_quarantined("school-slug")
```

## Architecture

### Domain Structure

- **Locations**: Geographic hierarchy (countries → federal states → counties → cities → schools)
- **Periods**: Holiday and vacation time periods
- **Calendars**: Holiday/vacation types and religions
- **Maps**: Address and zip code mapping

### Data Model

All locations (countries, federal states, counties, cities, schools) are stored in a single hierarchical table with parent-child relationships. This enables efficient querying up the location chain.

Periods store the actual holiday and vacation dates, associated with locations and holiday types. The system supports religious holidays, school-specific dates, and various visibility flags.

### Styling

The application uses **Tailwind CSS** with a centralized style configuration (`MehrSchulferien.StyleConfig`) managing consistent colors for different day types:

- **Holidays** (Feiertage): Blue theme
- **Vacations** (Schulferien): Green theme  
- **Weekends** (Wochenenden): Gray theme
- **Bridge days** (Brückentage): Yellow theme

## Environment Variables

### Optional: SerpApi for School Data Enrichment

```bash
export SERPAPI_API_KEY="your_serpapi_key_here"
```

Used by `mix search_school` to fetch school information (homepage, phone, social media) from search engines. Get your API key at [serpapi.com](https://serpapi.com).

## Database Restore

To restore a production database backup in development:

```bash
# Replace production database/user names with development ones
sed -i 's/mehr_schulferien_2020_prod/mehr_schulferien_dev/g' backup.sql
sed -i 's/mehrschul2020/postgres/g' backup.sql

# Drop existing database and restore
psql -U postgres -c "DROP DATABASE IF EXISTS mehr_schulferien_dev;"
psql -U postgres -f backup.sql
```

## Contributing

See the [contributing guide](https://github.com/mehr-schulferien-de/www.mehr-schulferien.de/blob/master/CONTRIBUTING.md) for more information about setting up your development environment and opening pull requests.

