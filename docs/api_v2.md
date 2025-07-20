# API v2.0 Documentation

## Overview

The mehr-schulferien.de API v2.0 provides programmatic access to school vacation and public holiday data for Germany. The API is RESTful and returns JSON for most endpoints, with special formats available for calendar exports (iCal) and contact information (vCard).

Base URL: `https://www.mehr-schulferien.de/api/v2.0/`

## Endpoints

### Locations

#### List all locations
```
GET /api/v2.0/locations
```

Returns a list of all locations (countries, federal states, counties, cities, schools).

#### Get specific location
```
GET /api/v2.0/locations/:id
```

Returns details for a specific location by ID.

### Periods

#### List all periods
```
GET /api/v2.0/periods
```

Returns a list of all periods (holidays and vacations).

#### Get specific period
```
GET /api/v2.0/periods/:id
```

Returns details for a specific period by ID.

### Holiday/Vacation Types

#### List all types
```
GET /api/v2.0/holiday_or_vacation_types
```

Returns a list of all holiday and vacation types.

#### Get specific type
```
GET /api/v2.0/holiday_or_vacation_types/:id
```

Returns details for a specific holiday/vacation type by ID.

### School vCards

#### Download school vCard
```
GET /api/v2.0/vcards/schools/:slug
```

Returns a vCard (.vcf) file with school contact information.

### iCalendar Export

#### Export location calendar
```
GET /api/v2.0/icalendars/location/:slug
```

Returns an iCalendar (.ics) file with vacation and holiday data for a location.

**Parameters:**
- `:slug` (required) - The slug identifier of the location
- `vacation_types` (optional) - Filter for vacation types
  - `"school"` (default) - Only school vacation periods
  - `"all"` - Both school vacation periods and public holidays
- `year` (required) - The year for the calendar data (integer)
- `calendar_year` (optional) - Boolean parameter
  - `"true"` - Calendar year (January 1 to December 31)
  - `"false"` or omitted (default) - School year (August 1 to July 31 of next year)

**Examples:**
```bash
# School vacations for Hessen in school year 2021/2022
GET /api/v2.0/icalendars/location/hessen?vacation_types=school&year=2021

# All holidays for Bayern in calendar year 2022
GET /api/v2.0/icalendars/location/bayern?vacation_types=all&year=2022&calendar_year=true

# School vacations for Berlin in school year 2023/2024
GET /api/v2.0/icalendars/location/berlin?vacation_types=school&year=2023
```

**Response:**
- Content-Type: `text/calendar; charset=utf-8`
- Content-Disposition: `attachment; filename=Schulferien_{Location}_{Year}.ics`

## Known Issues and Limitations

### Slug Ambiguity (v2.0)

In API v2.0, location slugs may not be unique across different location types. For example, there might be both a federal state and a city with the slug "hessen". When this occurs:

1. **Current Behavior**: The API prioritizes federal states when multiple locations share the same slug
2. **Impact**: If you request `/api/v2.0/icalendars/location/hessen`, you will receive data for the federal state Hessen, even if a city named Hessen also exists
3. **Workaround**: Currently, there's no way to specifically request data for a non-federal-state location if a federal state with the same slug exists

### Planned Improvements (v2.1)

The upcoming API v2.1 will address the slug ambiguity issue with one or more of these approaches:
- Location type prefixes in URLs (e.g., `/federal-state/hessen`, `/city/hessen`)
- Unique slug enforcement across all location types
- Additional query parameters to specify location type

## Response Formats

### JSON Responses

Most endpoints return JSON with the following general structure:

```json
{
  "data": {
    // Resource data
  },
  "meta": {
    // Metadata about the response
  }
}
```

### iCalendar Format

The iCal endpoint returns standard iCalendar format (RFC 5545) with events for each vacation/holiday period:

```
BEGIN:VCALENDAR
VERSION:2.0
CALSCALE:GREGORIAN
BEGIN:VEVENT
DTSTART;VALUE=DATE:20211011
DTEND;VALUE=DATE:20211024
SUMMARY:Herbstferien (Hessen)
LOCATION:Hessen
URL:https://www.mehr-schulferien.de/ferien/d/bundesland/hessen/2021
END:VEVENT
END:VCALENDAR
```

Note: The `DTEND` date is exclusive (the vacation ends the day before this date).

## Rate Limiting

Currently, no rate limiting is enforced on the API. However, please be respectful and avoid making excessive requests.

## Support

For questions or issues with the API, please open an issue on the [GitHub repository](https://github.com/mehr-schulferien-de/www.mehr-schulferien.de).