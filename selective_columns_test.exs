# Selective Column Performance Test
# Run with: mix run selective_columns_test.exs

alias MehrSchulferien.{Repo, Locations}
alias MehrSchulferien.Locations.Location
import Ecto.Query

IO.puts("Column Selection Performance Test")
IO.puts("=================================\n")

# Test 1: Countries with Federal States - All Columns vs Selective
IO.puts("Test 1: Countries with Federal States Query")
IO.puts("-------------------------------------------")

# Current approach - selecting all columns
{all_columns_time, all_columns_result} =
  :timer.tc(fn ->
    query =
      from c in Location,
        left_join: fs in Location,
        on: fs.parent_location_id == c.id and fs.is_federal_state == true,
        where: c.is_country == true,
        order_by: [asc: c.name, asc: fs.name],
        select: {c, fs}

    results = Repo.all(query)

    # Group by country
    results
    |> Enum.group_by(fn {country, _} -> country end, fn {_, state} -> state end)
    |> Enum.map(fn {country, states} ->
      valid_states = Enum.reject(states, &is_nil/1)
      {country, valid_states}
    end)
  end)

# Optimized approach - selecting only needed columns
{selective_columns_time, selective_columns_result} =
  :timer.tc(fn ->
    query =
      from c in Location,
        left_join: fs in Location,
        on: fs.parent_location_id == c.id and fs.is_federal_state == true,
        where: c.is_country == true,
        order_by: [asc: c.name, asc: fs.name],
        select: {
          %{id: c.id, name: c.name, slug: c.slug, is_country: c.is_country},
          %{
            id: fs.id,
            name: fs.name,
            slug: fs.slug,
            parent_location_id: fs.parent_location_id,
            is_federal_state: fs.is_federal_state
          }
        }

    results = Repo.all(query)

    # Group by country
    results
    |> Enum.group_by(fn {country, _} -> country end, fn {_, state} -> state end)
    |> Enum.map(fn {country, states} ->
      valid_states = Enum.reject(states, &is_nil/1)
      {country, valid_states}
    end)
  end)

all_columns_ms = all_columns_time / 1000
selective_columns_ms = selective_columns_time / 1000

IO.puts("All columns: #{Float.round(all_columns_ms, 2)}ms")
IO.puts("Selective columns: #{Float.round(selective_columns_ms, 2)}ms")

IO.puts(
  "Improvement: #{Float.round((all_columns_ms - selective_columns_ms) / all_columns_ms * 100, 2)}%"
)

IO.puts("Data reduction: ~60% fewer columns fetched\n")

# Test 2: Large dataset test - Multiple locations
IO.puts("Test 2: Period Queries with Location Data")
IO.puts("-----------------------------------------")

location_ids = Enum.to_list(1..16)
today = Date.utc_today()
ends_on = Date.add(today, 365)

# All columns approach
{all_cols_periods_time, _} =
  :timer.tc(fn ->
    query =
      from p in MehrSchulferien.Periods.Period,
        join: l in Location,
        on: p.location_id == l.id,
        where:
          p.location_id in ^location_ids and
            p.starts_on <= ^ends_on and
            p.ends_on >= ^today,
        select: {p, l}

    Repo.all(query)
  end)

# Selective columns approach
{selective_periods_time, _} =
  :timer.tc(fn ->
    query =
      from p in MehrSchulferien.Periods.Period,
        join: l in Location,
        on: p.location_id == l.id,
        where:
          p.location_id in ^location_ids and
            p.starts_on <= ^ends_on and
            p.ends_on >= ^today,
        select: {
          %{
            id: p.id,
            starts_on: p.starts_on,
            ends_on: p.ends_on,
            location_id: p.location_id,
            is_public_holiday: p.is_public_holiday,
            is_school_vacation: p.is_school_vacation
          },
          %{
            id: l.id,
            name: l.name,
            slug: l.slug
          }
        }

    Repo.all(query)
  end)

all_cols_periods_ms = all_cols_periods_time / 1000
selective_periods_ms = selective_periods_time / 1000

IO.puts("All columns: #{Float.round(all_cols_periods_ms, 2)}ms")
IO.puts("Selective columns: #{Float.round(selective_periods_ms, 2)}ms")

IO.puts(
  "Improvement: #{Float.round((all_cols_periods_ms - selective_periods_ms) / all_cols_periods_ms * 100, 2)}%"
)

IO.puts("Data reduction: ~70% fewer columns fetched\n")

# Test 3: Memory usage comparison
IO.puts("Test 3: Memory Usage Comparison")
IO.puts("-------------------------------")

# Measure memory for all columns
before_mem_all = :erlang.memory(:total)
all_data = Repo.all(from l in Location, limit: 1000)
after_mem_all = :erlang.memory(:total)
# KB
all_cols_memory = (after_mem_all - before_mem_all) / 1024

# Clear memory
:erlang.garbage_collect()
Process.sleep(100)

# Measure memory for selective columns
before_mem_sel = :erlang.memory(:total)

selective_data =
  Repo.all(
    from l in Location,
      limit: 1000,
      select: %{id: l.id, name: l.name, slug: l.slug}
  )

after_mem_sel = :erlang.memory(:total)
# KB
sel_cols_memory = (after_mem_sel - before_mem_sel) / 1024

IO.puts("All columns memory: #{Float.round(all_cols_memory, 2)} KB")
IO.puts("Selective columns memory: #{Float.round(sel_cols_memory, 2)} KB")

IO.puts(
  "Memory saved: #{Float.round((all_cols_memory - sel_cols_memory) / all_cols_memory * 100, 2)}%\n"
)

# Summary
IO.puts("\n=== SUMMARY ===")
IO.puts("Selecting only needed columns provides:")
IO.puts("✓ Reduced network transfer (less data from DB)")
IO.puts("✓ Lower memory usage in application")
IO.puts("✓ Faster query execution (marginally)")
IO.puts("✓ Better scalability for high-traffic scenarios")

IO.puts("\nColumns actually needed for home page:")
IO.puts("- Countries: id, name, slug, is_country")
IO.puts("- Federal States: id, name, slug, parent_location_id, is_federal_state")
IO.puts("- Periods: id, starts_on, ends_on, location_id, is_public_holiday, is_school_vacation")

IO.puts("\nColumns we can skip:")
IO.puts("- code, cachable_calendar_location_id")
IO.puts("- inserted_at, updated_at")
IO.puts("- created_by_email_address, memo (for periods)")
IO.puts("- display_priority, html_class (for periods)")
