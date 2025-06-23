defmodule Mix.Tasks.PerformanceTest do
  @moduledoc """
  Mix task to test database performance before and after optimizations.

  Usage:
    mix performance_test
  """

  use Mix.Task

  alias MehrSchulferien.{Locations, Periods}

  @shortdoc "Run database performance tests"

  def run(_args) do
    Mix.Task.run("app.start")

    IO.puts("=== Database Performance Test ===\n")

    # Test parameters
    today = Date.utc_today()
    number_of_days = 80
    ends_on = Date.add(today, number_of_days)

    IO.puts("Test Parameters:")
    IO.puts("- Start Date: #{today}")
    IO.puts("- End Date: #{ends_on}")
    IO.puts("- Duration: #{number_of_days} days\n")

    # Test 1: Basic location queries
    IO.puts("Test 1: Location Queries")

    {time1, countries} =
      measure_time(fn ->
        Locations.list_countries()
      end)

    IO.puts("- Countries: #{Float.round(time1, 2)}ms (#{length(countries)} results)")

    if length(countries) > 0 do
      country = List.first(countries)

      {time2, federal_states} =
        measure_time(fn ->
          Locations.list_federal_states(country)
        end)

      IO.puts("- Federal states: #{Float.round(time2, 2)}ms (#{length(federal_states)} results)")

      # Test optimized vs regular approach
      {time3, _} =
        measure_time(fn ->
          Locations.list_countries_with_federal_states_optimized()
        end)

      IO.puts("- Countries+States (optimized): #{Float.round(time3, 2)}ms")

      {time4, _} =
        measure_time(fn ->
          Locations.list_countries_with_federal_states_selective()
        end)

      IO.puts("- Countries+States (selective): #{Float.round(time4, 2)}ms")

      # Test periods query
      all_location_ids = [country.id | Enum.map(federal_states, & &1.id)]

      {time5, periods} =
        measure_time(fn ->
          Periods.list_school_free_periods_optimized(all_location_ids, today, ends_on)
        end)

      IO.puts("- Periods (optimized): #{Float.round(time5, 2)}ms (#{length(periods)} results)")

      # Test slug lookup
      {time6, _} =
        measure_time(fn ->
          try do
            Locations.get_location_by_slug!(country.slug)
          rescue
            _ -> nil
          end
        end)

      IO.puts("- Slug lookup: #{Float.round(time6, 2)}ms")

      total_time = time1 + time2 + time3 + time4 + time5 + time6
      IO.puts("\nTotal Query Time: #{Float.round(total_time, 2)}ms")

      # Performance summary
      IO.puts("\n=== Performance Summary ===")
      IO.puts("- Basic approach: #{Float.round(time1 + time2, 2)}ms")
      IO.puts("- Optimized approach: #{Float.round(time3, 2)}ms")
      IO.puts("- Selective approach: #{Float.round(time4, 2)}ms")

      if time3 > 0 do
        improvement = (time1 + time2 - time3) / (time1 + time2) * 100
        IO.puts("- Improvement: #{Float.round(improvement, 1)}%")
      end

      total_time
    else
      IO.puts("No test data available")
      0.0
    end
  end

  defp measure_time(fun) do
    start = System.monotonic_time(:microsecond)
    result = fun.()
    finish = System.monotonic_time(:microsecond)
    time_ms = (finish - start) / 1000
    {time_ms, result}
  end
end
