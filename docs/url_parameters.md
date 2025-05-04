# URL Parameters

This document outlines the URL parameters available for customizing the vacation timeline view.

## Available Parameters

### Vacation Timeline Parameters

These parameters can be used with the `/new` route to customize the vacation timeline.

| Parameter | Type    | Description                                         | Default       | Example           |
|-----------|---------|-----------------------------------------------------|---------------|-------------------|
| `today`   | String  | Sets the starting date in format DD.MM.YYYY         | Current date  | `today=10.04.2025`|
| `days`    | Integer | Number of days to display (between 1-365)           | 90            | `days=180`        |

## Examples

### Default View
```
/new
```
Shows the vacation timeline starting from today and displays the next 90 days.

### Custom Start Date
```
/new?today=01.09.2024
```
Shows the vacation timeline starting from September 1, 2024 and displays the next 90 days.

### Custom Number of Days
```
/new?days=180
```
Shows the vacation timeline starting from today and displays the next 180 days.

### Combined Parameters
```
/new?today=01.09.2024&days=180
```
Shows the vacation timeline starting from September 1, 2024 and displays the next 180 days.

## Notes

- When using the `today` parameter, the page will include a `noindex` meta tag to prevent search engine indexing
- Invalid parameter values will fall back to their defaults
- The `days` parameter is limited to a maximum of 365 days to ensure reasonable performance 