# Performance test script
# Run with: mix run test_performance.exs

alias MehrSchulferien.{Locations, Periods, BridgeDays}

# Simulate the old approach
defmodule OldApproach do
  def fetch_data(start_date, ends_on, current_year) do
    # Get countries (1 query)
    countries = Locations.list_countries()

    # Get federal states for each country (N queries where N = number of countries)
    federal_states_by_country =
      Enum.reduce(countries, %{}, fn country, acc ->
        states = Locations.list_federal_states(country)
        Map.put(acc, country.id, states)
      end)

    # Get all location IDs
    all_location_ids =
      Enum.flat_map(countries, fn country ->
        states = Map.get(federal_states_by_country, country.id, [])
        [country.id | Enum.map(states, & &1.id)]
      end)

    # Get periods 
    periods = Periods.list_school_free_periods_with_preload(all_location_ids, start_date, ends_on)

    # Check bridge days (48 queries - 16 states × 3 years)
    bridge_days_count =
      Enum.reduce(countries, 0, fn country, acc1 ->
        states = Map.get(federal_states_by_country, country.id, [])

        acc1 +
          Enum.reduce(states, 0, fn state, acc2 ->
            acc2 +
              Enum.count(current_year..(current_year + 2), fn year ->
                BridgeDays.has_bridge_days?([country.id, state.id], year)
              end)
          end)
      end)

    {length(periods), bridge_days_count}
  end
end

# Simulate the new approach
defmodule NewApproach do
  def fetch_data(start_date, ends_on, current_year) do
    # Single query for countries with states
    countries_with_states = Locations.list_countries_with_federal_states_optimized()

    # Extract location IDs
    all_location_ids =
      Enum.flat_map(countries_with_states, fn {country, states} ->
        [country.id | Enum.map(states, & &1.id)]
      end)

    # Optimized periods query
    periods = Periods.list_school_free_periods_optimized(all_location_ids, start_date, ends_on)

    # Bulk bridge days check
    years = [current_year, current_year + 1, current_year + 2]

    bridge_days_count =
      Enum.reduce(countries_with_states, 0, fn {country, states}, acc ->
        result = BridgeDays.bulk_has_bridge_days?(country, states, years)
        acc + Enum.count(result, fn {_, has_bridge} -> has_bridge end)
      end)

    {length(periods), bridge_days_count}
  end
end

# Test parameters
today = Date.utc_today()
current_year = today.year
ends_on = Date.add(today, 80)

IO.puts("Performance Test Results")
IO.puts("========================\n")

# Warm up
IO.puts("Warming up...")
OldApproach.fetch_data(today, ends_on, current_year)
NewApproach.fetch_data(today, ends_on, current_year)

# Measure old approach
IO.puts("Testing old approach...")

{old_time, {old_periods, old_bridge_days}} =
  :timer.tc(fn ->
    OldApproach.fetch_data(today, ends_on, current_year)
  end)

old_ms = old_time / 1000
IO.puts("Old approach: #{Float.round(old_ms, 2)}ms")
IO.puts("  - Periods found: #{old_periods}")
IO.puts("  - Bridge days checks: #{old_bridge_days}\n")

# Measure new approach
IO.puts("Testing new approach...")

{new_time, {new_periods, new_bridge_days}} =
  :timer.tc(fn ->
    NewApproach.fetch_data(today, ends_on, current_year)
  end)

new_ms = new_time / 1000
IO.puts("New approach: #{Float.round(new_ms, 2)}ms")
IO.puts("  - Periods found: #{new_periods}")
IO.puts("  - Bridge days checks: #{new_bridge_days}\n")

# Calculate improvement
improvement = Float.round((old_ms - new_ms) / old_ms * 100, 2)
speedup = Float.round(old_ms / new_ms, 2)

IO.puts("Performance Improvement")
IO.puts("----------------------")
IO.puts("Improvement: #{improvement}%")
IO.puts("Speedup: #{speedup}x faster")
IO.puts("Time saved: #{Float.round(old_ms - new_ms, 2)}ms")
