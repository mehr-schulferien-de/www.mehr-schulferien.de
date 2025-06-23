# Field Optimization Analysis

## Executive Summary

Analysis reveals that most Ecto queries fetch 100% of database fields but only use 20-50% of them in views/templates. This creates unnecessary data transfer overhead that can be eliminated through selective field queries.

## Unused Fields by Table

### 1. **locations** Table

**Total Fields**: 14 fields + timestamps (16 total)
**Commonly Fetched But Unused Fields**:
- `inserted_at` - NEVER used in any view
- `updated_at` - NEVER used in any view  
- `cachable_calendar_location_id` - Rarely used (only in specific calendar operations)
- `code` - Only used for countries (e.g., "D" for Deutschland)

**Usage Patterns by Query Type**:

| Query Type | Fields Actually Used | Fields Fetched | Waste % |
|------------|---------------------|----------------|---------|
| Country List | 4 (id, name, slug, is_country) | 16 | 75% |
| Federal State List | 5 (id, name, slug, parent_location_id, is_federal_state) | 16 | 69% |
| City List | 6 (id, name, slug, parent_location_id, is_city, zip_codes) | 16 | 62% |
| School Display | 7 (id, name, slug, parent_location_id, is_school, address, zip_codes) | 16 | 56% |

### 2. **periods** Table

**Total Fields**: 17 fields + timestamps + 2 virtual (21 total)
**Commonly Fetched But Unused Fields**:
- `inserted_at` - NEVER used
- `updated_at` - NEVER used
- `created_by_email_address` - NEVER displayed to users
- `memo` - Internal notes, never displayed
- `religion_id` - Only relevant for religious holidays
- `is_listed_below_month` - Rarely used display flag
- `adjoining_duration` (virtual) - Only used in bridge day calculations
- `array_agg` (virtual) - Only used in specific queries

**Usage Patterns by View Type**:

| View Type | Fields Actually Used | Fields Fetched | Waste % |
|-----------|---------------------|----------------|---------|
| Timeline View | 8 (id, starts_on, ends_on, location_id, html_class, display_priority, is_public_holiday, is_school_vacation) | 21 | 62% |
| Calendar View | 6 (starts_on, ends_on, html_class, is_public_holiday, is_school_vacation, holiday_type.name) | 21 | 71% |
| Table View | 5 (starts_on, ends_on, display_priority, holiday_type.name, holiday_type.slug) | 21 | 76% |
| API Response | 8 (excludes all internal fields) | 21 | 62% |

### 3. **holiday_or_vacation_types** Table

**Total Fields**: 15 fields + timestamps (17 total)
**Commonly Fetched But Unused Fields**:
- `inserted_at` - NEVER used
- `updated_at` - NEVER used
- `wikipedia_url` - Rarely displayed
- All `default_*` fields (8 fields) - Only used when creating new periods, not for display
- `country_location_id` - Internal reference
- `default_religion_id` - Internal reference

**Usage Patterns**:

| Context | Fields Actually Used | Fields Fetched | Waste % |
|---------|---------------------|----------------|---------|
| Period Display | 4 (id, name, slug, colloquial) | 17 | 76% |
| Holiday List | 5 (id, name, slug, colloquial, default_is_school_vacation) | 17 | 71% |

### 4. **addresses** Table

**Total Fields**: 14 fields + timestamps (16 total)
**Commonly Fetched But Unused Fields**:
- `inserted_at` - NEVER used
- `updated_at` - NEVER used
- `official_id` - Internal reference, not displayed
- `line1` - Often empty/redundant with street
- `fax_number` - Outdated, rarely populated

**Usage Patterns**:

| View Type | Fields Actually Used | Fields Fetched | Waste % |
|-----------|---------------------|----------------|---------|
| School Info | 8 (street, zip_code, city, email_address, phone_number, homepage_url, lat, lon) | 16 | 50% |
| Contact Display | 6 (street, zip_code, city, email_address, phone_number, homepage_url) | 16 | 62% |
| Map Display | 4 (lat, lon, street, city) | 16 | 75% |

### 5. **zip_codes** Table

**Total Fields**: 5 fields + timestamps (7 total)
**Commonly Fetched But Unused Fields**:
- `inserted_at` - NEVER used
- `updated_at` - NEVER used
- `country_location_id` - Internal reference

**Usage Patterns**:

| Context | Fields Actually Used | Fields Fetched | Waste % |
|---------|---------------------|----------------|---------|
| Display | 2 (value, slug) | 7 | 71% |

## Performance Impact Estimation

Based on the analysis above, implementing selective field queries could reduce data transfer by:

- **Location queries**: 56-75% reduction
- **Period queries**: 62-76% reduction  
- **Holiday type queries**: 71-76% reduction
- **Address queries**: 50-75% reduction

### Real-World Impact

For a typical page load that fetches:
- 1 country + 16 federal states = 17 location records × 16 fields = 272 fields
- 28 periods × 21 fields = 588 fields
- 28 holiday types × 17 fields = 476 fields
- **Total**: 1,336 fields fetched

With optimization:
- 17 locations × 5 fields (avg) = 85 fields
- 28 periods × 8 fields = 224 fields
- 28 holiday types × 4 fields = 112 fields
- **Total**: 421 fields fetched

**Reduction**: 915 fields (68.5% less data transfer)

## Recommendations

### 1. **Immediate Actions**
- Never fetch `inserted_at` and `updated_at` unless specifically needed for audit trails
- Create view-specific query functions that only select required fields
- Use existing optimized functions (`list_school_free_periods_optimized`) as templates

### 2. **High-Priority Optimizations**
- **Location queries**: Implement selective queries for all location list functions
- **Period queries**: Create view-specific queries (timeline, calendar, table)
- **Holiday type preloads**: Only select `id`, `name`, `slug`, `colloquial`

### 3. **Implementation Strategy**
- Start with highest-frequency queries (home page, federal state pages)
- Create new functions with `_selective` suffix for backward compatibility
- Update cached queries to use selective versions
- Measure impact with performance benchmarks

### 4. **Code Patterns to Follow**

```elixir
# Good: Selective query
from(l in Location,
  where: l.is_country == true,
  select: %Location{
    id: l.id,
    name: l.name,
    slug: l.slug,
    is_country: l.is_country
  }
)

# Bad: Default query fetching all fields
from(l in Location, where: l.is_country == true)
```

### 5. **Testing Strategy**
- Ensure all views still render correctly with reduced field sets
- Add tests that verify only necessary fields are loaded
- Monitor for any `nil` access errors in production

## Conclusion

The codebase currently transfers 2-4x more data than necessary from the database. By implementing selective field queries, we can achieve:

- **68.5% reduction** in data transfer volume
- Faster query execution times
- Reduced memory usage
- Better scalability under load

The existing `list_school_free_periods_optimized/3` function demonstrates this approach works well and should be extended throughout the codebase.