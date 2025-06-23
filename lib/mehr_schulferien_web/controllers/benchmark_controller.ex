defmodule MehrSchulferienWeb.BenchmarkController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Locations, Periods, BridgeDays, Calendars.DateHelpers}

  def benchmark(conn, _params) do
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year
    number_of_days = 80
    ends_on = Date.add(today, number_of_days)

    # Benchmark old approach
    {old_time, _old_result} =
      :timer.tc(fn ->
        # Get countries with federal states (2 queries)
        countries = Locations.list_countries()

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

        # Get periods (with N+1 preload)
        _periods = Periods.list_school_free_periods_with_preload(all_location_ids, today, ends_on)

        # Check bridge days (48 queries - 16 states × 3 years)
        Enum.each(countries, fn country ->
          states = Map.get(federal_states_by_country, country.id, [])

          Enum.each(states, fn state ->
            Enum.each(current_year..(current_year + 2), fn year ->
              BridgeDays.has_bridge_days?([country.id, state.id], year)
            end)
          end)
        end)
      end)

    # Benchmark new optimized approach  
    {new_time, _new_result} =
      :timer.tc(fn ->
        # Single query for countries with states
        countries_with_states = Locations.list_countries_with_federal_states_optimized()

        # Extract location IDs
        all_location_ids =
          Enum.flat_map(countries_with_states, fn {country, states} ->
            [country.id | Enum.map(states, & &1.id)]
          end)

        # Optimized periods query
        _periods = Periods.list_school_free_periods_optimized(all_location_ids, today, ends_on)

        # Bulk bridge days check
        years = [current_year, current_year + 1, current_year + 2]

        Enum.each(countries_with_states, fn {country, states} ->
          BridgeDays.bulk_has_bridge_days?(country, states, years)
        end)
      end)

    old_ms = old_time / 1000
    new_ms = new_time / 1000
    improvement = Float.round((old_ms - new_ms) / old_ms * 100, 2)
    speedup = Float.round(old_ms / new_ms, 2)

    render(conn, "benchmark.html", %{
      old_time: Float.round(old_ms, 2),
      new_time: Float.round(new_ms, 2),
      improvement: improvement,
      speedup: speedup
    })
  end
end
