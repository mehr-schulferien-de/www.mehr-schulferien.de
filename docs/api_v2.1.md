# API v2.1 Documentation

## Overview

The mehr-schulferien.de API v2.1 provides a modern, RESTful interface for accessing school vacation and public holiday data for Germany. This version introduces significant improvements over v2.0, including clear separation of location types, consistent JSON API format, and elimination of slug ambiguity issues.

Base URL: `https://www.mehr-schulferien.de/api/v2.1/`

## Key Improvements in v2.1

1. **Clear Location Type Separation**: Each location type has its own dedicated endpoints
2. **No Slug Ambiguity**: Endpoints are specific to location types, eliminating conflicts
3. **Consistent JSON API Format**: All responses follow a predictable structure
4. **Better Error Handling**: Detailed error messages with appropriate HTTP status codes
5. **Pagination Support**: List endpoints support pagination with metadata
6. **Enhanced Filtering**: More options for filtering results

## Authentication

Currently, the API does not require authentication. This may change in future versions.

## Response Format

All JSON responses follow this structure:

```json
{
  "data": { ... },  // or array for list endpoints
  "meta": {
    "api_version": "2.1",
    // Additional metadata
  }
}
```

For paginated responses:
```json
{
  "data": [ ... ],
  "meta": {
    "api_version": "2.1",
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total_pages": 5,
      "total_entries": 95
    }
  }
}
```

## Common Parameters

### Pagination Parameters
- `page` (integer, default: 1) - Page number
- `per_page` (integer, default: 20, max: 100) - Items per page

### Date Range Parameters
- `start_date` (ISO 8601 date) - Start of date range
- `end_date` (ISO 8601 date) - End of date range

### iCalendar Parameters
- `year` (integer, required) - The year for calendar data
- `vacation_types` (string) - Filter vacation types:
  - `"school"` (default) - Only school vacations
  - `"all"` - Both school vacations and public holidays
- `calendar_year` (boolean) - Calendar format:
  - `"true"` - Calendar year (Jan 1 - Dec 31)
  - `"false"` (default) - School year (Aug 1 - Jul 31)

## Endpoints

### Federal States

#### List all federal states
```
GET /api/v2.1/federal-states
```

Query parameters:
- `country` (string) - Filter by country slug (e.g., "d" for Deutschland)
- Pagination parameters

Example:
```bash
GET /api/v2.1/federal-states?country=d&page=1&per_page=20
```

#### Get specific federal state
```
GET /api/v2.1/federal-states/:slug
```

Example:
```bash
GET /api/v2.1/federal-states/hessen
```

#### Get periods for a federal state
```
GET /api/v2.1/federal-states/:slug/periods
```

Query parameters:
- `start_date` - Start of date range (default: today)
- `end_date` - End of date range (default: start_date + 365 days)
- `type` - Filter by period type:
  - `"vacation"` - Only school vacations
  - `"holiday"` - Only public holidays
  - (omit for both)

Example:
```bash
GET /api/v2.1/federal-states/bayern/periods?start_date=2024-01-01&end_date=2024-12-31&type=vacation
```

#### Get iCalendar for a federal state
```
GET /api/v2.1/federal-states/:slug/icalendar
```

Query parameters:
- `year` (required) - The year
- `vacation_types` - "school" or "all"
- `calendar_year` - "true" or "false"

Example:
```bash
GET /api/v2.1/federal-states/berlin/icalendar?year=2024&vacation_types=all&calendar_year=true
```

### Cities

#### List all cities
```
GET /api/v2.1/cities
```

Query parameters:
- `federal_state` - Filter by federal state slug
- `county` - Filter by county slug
- Pagination parameters

#### Get specific city
```
GET /api/v2.1/cities/:slug
```

#### Get periods for a city
```
GET /api/v2.1/cities/:slug/periods
```

#### Get iCalendar for a city
```
GET /api/v2.1/cities/:slug/icalendar
```

### Counties

#### List all counties
```
GET /api/v2.1/counties
```

Query parameters:
- `federal_state` - Filter by federal state slug
- Pagination parameters

#### Get specific county
```
GET /api/v2.1/counties/:slug
```

#### Get periods for a county
```
GET /api/v2.1/counties/:slug/periods
```

#### Get iCalendar for a county
```
GET /api/v2.1/counties/:slug/icalendar
```

### Schools

#### List all schools
```
GET /api/v2.1/schools
```

Query parameters:
- `city` - Filter by city slug
- `federal_state` - Filter by federal state slug
- Pagination parameters

#### Get specific school
```
GET /api/v2.1/schools/:slug
```

Response includes address information:
```json
{
  "data": {
    "id": 12345,
    "name": "Gymnasium München",
    "slug": "gymnasium-muenchen",
    "type": "school",
    "address": {
      "street": "Hauptstraße 1",
      "zip_code": "80331",
      "city": "München",
      "phone": "+49 89 123456",
      "fax": "+49 89 123457",
      "email": "info@gymnasium-muenchen.de",
      "homepage": "https://www.gymnasium-muenchen.de"
    },
    "links": {
      "self": "https://www.mehr-schulferien.de/api/v2.1/schools/gymnasium-muenchen",
      "periods": "https://www.mehr-schulferien.de/api/v2.1/schools/gymnasium-muenchen/periods",
      "icalendar": "https://www.mehr-schulferien.de/api/v2.1/schools/gymnasium-muenchen/icalendar"
    }
  },
  "meta": {
    "api_version": "2.1"
  }
}
```

#### Get periods for a school
```
GET /api/v2.1/schools/:slug/periods
```

#### Get iCalendar for a school
```
GET /api/v2.1/schools/:slug/icalendar
```

#### Get vCard for a school
```
GET /api/v2.1/schools/:slug/vcard
```

Returns a vCard (.vcf) file with school contact information.

### Countries

#### List all countries
```
GET /api/v2.1/countries
```

#### Get specific country
```
GET /api/v2.1/countries/:slug
```

#### Get federal states for a country
```
GET /api/v2.1/countries/:slug/federal-states
```

### Periods

#### List all periods
```
GET /api/v2.1/periods
```

Query parameters:
- `start_date` - Start of date range
- `end_date` - End of date range
- `location_id` - Filter by location ID (includes sub-locations)
- `type` - Filter by type ("vacation" or "holiday")
- Pagination parameters

#### Get specific period
```
GET /api/v2.1/periods/:id
```

### Holiday/Vacation Types

#### List all types
```
GET /api/v2.1/holiday-vacation-types
```

Query parameters:
- `country_id` - Filter by country ID
- Pagination parameters

#### Get specific type
```
GET /api/v2.1/holiday-vacation-types/:id
```

## Response Examples

### Successful Response (Single Resource)
```json
{
  "data": {
    "id": 8,
    "name": "Hessen",
    "slug": "hessen",
    "code": "HE",
    "type": "federal_state",
    "parent_location_id": 1,
    "links": {
      "self": "https://www.mehr-schulferien.de/api/v2.1/federal-states/hessen",
      "periods": "https://www.mehr-schulferien.de/api/v2.1/federal-states/hessen/periods",
      "icalendar": "https://www.mehr-schulferien.de/api/v2.1/federal-states/hessen/icalendar"
    }
  },
  "meta": {
    "api_version": "2.1"
  }
}
```

### Successful Response (List with Pagination)
```json
{
  "data": [
    {
      "id": 1,
      "name": "Baden-Württemberg",
      "slug": "baden-wuerttemberg",
      "type": "federal_state"
    },
    {
      "id": 2,
      "name": "Bayern",
      "slug": "bayern",
      "type": "federal_state"
    }
  ],
  "meta": {
    "api_version": "2.1",
    "pagination": {
      "page": 1,
      "per_page": 20,
      "total_pages": 1,
      "total_entries": 16
    }
  }
}
```

### Error Response
```json
{
  "errors": [
    {
      "status": "404",
      "title": "Not Found",
      "detail": "The requested resource could not be found."
    }
  ],
  "meta": {
    "api_version": "2.1"
  }
}
```

## Error Codes

- `400 Bad Request` - Invalid parameters or request format
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation errors
- `500 Internal Server Error` - Server error

## Migration from v2.0 to v2.1

### Breaking Changes

1. **URL Structure**: Location-specific endpoints replace generic `/location/:slug`
   - v2.0: `/api/v2.0/icalendars/location/hessen`
   - v2.1: `/api/v2.1/federal-states/hessen/icalendar`

2. **Response Format**: Consistent JSON API format with data/meta structure
   - All responses now include metadata
   - Pagination information moved to meta.pagination

3. **Parameter Names**: Some parameters have been standardized
   - `vacation_types` remains the same for iCalendar endpoints
   - New filtering options for list endpoints

### Migration Examples

#### iCalendar URLs
```bash
# v2.0
GET /api/v2.0/icalendars/location/bayern?vacation_types=school&year=2024

# v2.1
GET /api/v2.1/federal-states/bayern/icalendar?vacation_types=school&year=2024
```

#### vCard URLs
```bash
# v2.0
GET /api/v2.0/vcards/schools/gymnasium-muenchen

# v2.1
GET /api/v2.1/schools/gymnasium-muenchen/vcard
```

## Best Practices

1. **Always specify location type**: Use the appropriate endpoint for your location type
2. **Handle pagination**: Check meta.pagination for total pages when fetching lists
3. **Use date ranges wisely**: Limit date ranges to reduce response size
4. **Cache responses**: iCalendar and period data changes infrequently
5. **Follow links**: Use the links provided in responses for related resources

## Rate Limiting

Currently no rate limiting is enforced, but please be respectful:
- Cache responses when possible
- Avoid making excessive requests
- Use pagination efficiently

## Support

For questions or issues with the API, please open an issue on the [GitHub repository](https://github.com/mehr-schulferien-de/www.mehr-schulferien.de).