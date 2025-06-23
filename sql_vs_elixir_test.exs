# SQL vs Elixir Performance Test
# Run with: mix run sql_vs_elixir_test.exs

alias MehrSchulferien.{Repo, Locations, Periods}
alias MehrSchulferien.Locations.Location
import Ecto.Query

IO.puts("SQL vs Elixir Performance Comparison")
IO.puts("=====================================\n")

# Test parameters
today = Date.utc_today()
start_date = today
ends_on = Date.add(today, 80)

# Test 1: Join in SQL vs Separate queries + Elixir merge
IO.puts("Test 1: Fetching Countries with Federal States")
IO.puts("----------------------------------------------")

# SQL Join approach
{sql_join_time, sql_join_result} =
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

# Elixir approach with separate queries
{elixir_time, elixir_result} =
  :timer.tc(fn ->
    countries = Repo.all(from l in Location, where: l.is_country == true)

    Enum.map(countries, fn country ->
      states =
        Repo.all(
          from l in Location,
            where: l.is_federal_state == true and l.parent_location_id == ^country.id,
            order_by: l.name
        )

      {country, states}
    end)
  end)

sql_join_ms = sql_join_time / 1000
elixir_ms = elixir_time / 1000

IO.puts("SQL Join: #{Float.round(sql_join_ms, 2)}ms")
IO.puts("Elixir with N+1: #{Float.round(elixir_ms, 2)}ms")
IO.puts("SQL is #{Float.round(elixir_ms / sql_join_ms, 2)}x faster\n")

# Test 2: Aggregations - SQL vs Elixir
IO.puts("Test 2: Period Aggregations")
IO.puts("---------------------------")

# Get location IDs for testing
location_ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]

# SQL aggregation
{sql_agg_time, sql_agg_result} =
  :timer.tc(fn ->
    query =
      from p in MehrSchulferien.Periods.Period,
        where:
          p.location_id in ^location_ids and
            p.starts_on <= ^ends_on and
            p.ends_on >= ^start_date,
        group_by: p.location_id,
        select: %{
          location_id: p.location_id,
          period_count: count(p.id),
          avg_duration: avg(fragment("? - ? + 1", p.ends_on, p.starts_on)),
          total_days: sum(fragment("? - ? + 1", p.ends_on, p.starts_on))
        }

    Repo.all(query)
  end)

# Elixir aggregation
{elixir_agg_time, elixir_agg_result} =
  :timer.tc(fn ->
    periods =
      Repo.all(
        from p in MehrSchulferien.Periods.Period,
          where:
            p.location_id in ^location_ids and
              p.starts_on <= ^ends_on and
              p.ends_on >= ^start_date
      )

    periods
    |> Enum.group_by(& &1.location_id)
    |> Enum.map(fn {location_id, location_periods} ->
      durations =
        Enum.map(location_periods, fn p ->
          Date.diff(p.ends_on, p.starts_on) + 1
        end)

      %{
        location_id: location_id,
        period_count: length(location_periods),
        avg_duration:
          if(length(durations) > 0, do: Enum.sum(durations) / length(durations), else: 0),
        total_days: Enum.sum(durations)
      }
    end)
  end)

sql_agg_ms = sql_agg_time / 1000
elixir_agg_ms = elixir_agg_time / 1000

IO.puts("SQL Aggregation: #{Float.round(sql_agg_ms, 2)}ms")
IO.puts("Elixir Aggregation: #{Float.round(elixir_agg_ms, 2)}ms")

if sql_agg_ms < elixir_agg_ms do
  IO.puts("SQL is #{Float.round(elixir_agg_ms / sql_agg_ms, 2)}x faster\n")
else
  IO.puts("Elixir is #{Float.round(sql_agg_ms / elixir_agg_ms, 2)}x faster\n")
end

# Test 3: Complex date range calculations
IO.puts("Test 3: Date Range Operations")
IO.puts("-----------------------------")

# SQL approach with date operations
{sql_date_time, _} =
  :timer.tc(fn ->
    query = """
    SELECT 
      location_id,
      COUNT(DISTINCT DATE(starts_on)) as unique_start_days,
      COUNT(*) FILTER (WHERE ends_on - starts_on > 7) as long_periods
    FROM periods
    WHERE location_id = ANY($1)
      AND starts_on <= $2
      AND ends_on >= $3
    GROUP BY location_id
    """

    Repo.query!(query, [location_ids, ends_on, start_date])
  end)

# Elixir approach
{elixir_date_time, _} =
  :timer.tc(fn ->
    periods =
      Repo.all(
        from p in MehrSchulferien.Periods.Period,
          where:
            p.location_id in ^location_ids and
              p.starts_on <= ^ends_on and
              p.ends_on >= ^start_date
      )

    periods
    |> Enum.group_by(& &1.location_id)
    |> Enum.map(fn {location_id, location_periods} ->
      unique_start_days =
        location_periods
        |> Enum.map(& &1.starts_on)
        |> Enum.uniq()
        |> length()

      long_periods =
        location_periods
        |> Enum.filter(fn p -> Date.diff(p.ends_on, p.starts_on) > 7 end)
        |> length()

      %{
        location_id: location_id,
        unique_start_days: unique_start_days,
        long_periods: long_periods
      }
    end)
  end)

sql_date_ms = sql_date_time / 1000
elixir_date_ms = elixir_date_time / 1000

IO.puts("SQL Date Operations: #{Float.round(sql_date_ms, 2)}ms")
IO.puts("Elixir Date Operations: #{Float.round(elixir_date_ms, 2)}ms")

if sql_date_ms < elixir_date_ms do
  IO.puts("SQL is #{Float.round(elixir_date_ms / sql_date_ms, 2)}x faster\n")
else
  IO.puts("Elixir is #{Float.round(sql_date_ms / elixir_date_ms, 2)}x faster\n")
end

# Summary and Recommendations
IO.puts("\n=== SUMMARY & RECOMMENDATIONS ===")
IO.puts("Based on the performance tests:\n")

IO.puts("1. For JOINS and data fetching:")
IO.puts("   → Use SQL joins to avoid N+1 queries")
IO.puts("   → Single query with joins beats multiple queries\n")

IO.puts("2. For AGGREGATIONS (COUNT, SUM, AVG):")

if sql_agg_ms < elixir_agg_ms do
  IO.puts("   → SQL aggregations are more efficient")
  IO.puts("   → Use SQL GROUP BY with aggregate functions")
else
  IO.puts("   → Elixir aggregations performed well")
  IO.puts("   → Consider data size and complexity")
end

IO.puts("\n3. For DATE OPERATIONS:")

if sql_date_ms < elixir_date_ms do
  IO.puts("   → SQL date functions are faster")
  IO.puts("   → Use PostgreSQL date functions when possible")
else
  IO.puts("   → Elixir date operations are competitive")
  IO.puts("   → Good for complex business logic")
end

IO.puts("\n4. GENERAL GUIDELINES:")
IO.puts("   → Filter data in SQL (WHERE clauses)")
IO.puts("   → Join related data in SQL")
IO.puts("   → Use SQL for simple aggregations")
IO.puts("   → Use Elixir for complex business logic")
IO.puts("   → Minimize data transfer between DB and app")
