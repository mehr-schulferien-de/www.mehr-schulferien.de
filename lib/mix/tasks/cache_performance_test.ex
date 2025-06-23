defmodule Mix.Tasks.CachePerformanceTest do
  @moduledoc """
  Comprehensive caching performance test to measure the impact of ETS caching.

  Usage:
    mix cache_performance_test
    mix cache_performance_test --runs 10
  """

  use Mix.Task

  alias MehrSchulferien.{Cache, Locations, Periods}

  @shortdoc "Run comprehensive caching performance tests"

  def run(args) do
    Mix.Task.run("app.start")

    {opts, _, _} = OptionParser.parse(args, switches: [runs: :integer])
    runs = Keyword.get(opts, :runs, 5)

    IO.puts("=== Comprehensive Caching Performance Test ===\n")
    IO.puts("Running #{runs} iterations of each test...\n")

    # Test parameters
    today = Date.utc_today()
    number_of_days = 80
    ends_on = Date.add(today, number_of_days)

    IO.puts("Test Parameters:")
    IO.puts("- Start Date: #{today}")
    IO.puts("- End Date: #{ends_on}")
    IO.puts("- Duration: #{number_of_days} days")
    IO.puts("- Test Runs: #{runs}\n")

    # Clear cache before starting
    Cache.clear_all_location_hierarchies()
    Cache.clear_stats()

    # Test 1: Location Hierarchy Performance
    IO.puts("=== Test 1: Location Hierarchy Caching ===")
    location_results = test_location_caching(runs)

    # Test 2: Periods Query Performance  
    IO.puts("\n=== Test 2: Periods Query Caching ===")
    periods_results = test_periods_caching(today, ends_on, runs)

    # Test 3: Full Page Load Simulation
    IO.puts("\n=== Test 3: Full Page Load Simulation ===")
    page_load_results = test_full_page_load(today, ends_on, runs)

    # Cache Statistics
    IO.puts("\n=== Cache Statistics ===")
    print_cache_stats()

    # Performance Summary
    IO.puts("\n=== Performance Summary ===")
    print_performance_summary(location_results, periods_results, page_load_results)

    # Memory Usage
    IO.puts("\n=== Memory Usage ===")
    print_memory_usage()
  end

  defp test_location_caching(runs) do
    # Test uncached performance
    uncached_times =
      Enum.map(1..runs, fn _ ->
        Cache.clear_all_location_hierarchies()
        measure_time(fn -> Locations.list_countries_with_federal_states_selective() end)
      end)

    uncached_avg = average(uncached_times)
    IO.puts("Uncached location queries: #{Float.round(uncached_avg, 2)}ms avg")

    # Warm up cache
    Locations.list_countries_with_federal_states_cached()

    # Test cached performance
    cached_times =
      Enum.map(1..runs, fn _ ->
        measure_time(fn -> Locations.list_countries_with_federal_states_cached() end)
      end)

    cached_avg = average(cached_times)
    IO.puts("Cached location queries: #{Float.round(cached_avg, 2)}ms avg")

    improvement = (uncached_avg - cached_avg) / uncached_avg * 100
    IO.puts("Improvement: #{Float.round(improvement, 1)}% faster")

    %{uncached: uncached_avg, cached: cached_avg, improvement: improvement}
  end

  defp test_periods_caching(start_date, end_date, runs) do
    # Get location IDs for testing
    countries_with_states = Locations.list_countries_with_federal_states_cached()

    all_location_ids =
      Enum.flat_map(countries_with_states, fn {country, federal_states} ->
        [country.id | Enum.map(federal_states, & &1.id)]
      end)

    # Test uncached performance
    uncached_times =
      Enum.map(1..runs, fn _ ->
        # Clear periods cache
        Periods.clear_periods_caches()

        measure_time(fn ->
          Periods.list_school_free_periods_optimized(all_location_ids, start_date, end_date)
        end)
      end)

    uncached_avg = average(uncached_times)
    IO.puts("Uncached periods queries: #{Float.round(uncached_avg, 2)}ms avg")

    # Warm up cache
    Periods.list_school_free_periods_cached(all_location_ids, start_date, end_date)

    # Test cached performance
    cached_times =
      Enum.map(1..runs, fn _ ->
        measure_time(fn ->
          Periods.list_school_free_periods_cached(all_location_ids, start_date, end_date)
        end)
      end)

    cached_avg = average(cached_times)
    IO.puts("Cached periods queries: #{Float.round(cached_avg, 2)}ms avg")

    improvement = (uncached_avg - cached_avg) / uncached_avg * 100
    IO.puts("Improvement: #{Float.round(improvement, 1)}% faster")

    %{uncached: uncached_avg, cached: cached_avg, improvement: improvement}
  end

  defp test_full_page_load(start_date, end_date, runs) do
    # Simulate full page load without cache
    uncached_times =
      Enum.map(1..runs, fn _ ->
        Cache.clear_all_location_hierarchies()
        Periods.clear_periods_caches()

        measure_time(fn ->
          # Simulate the full page load process
          countries_with_states = Locations.list_countries_with_federal_states_selective()

          all_location_ids =
            Enum.flat_map(countries_with_states, fn {country, federal_states} ->
              [country.id | Enum.map(federal_states, & &1.id)]
            end)

          _periods =
            Periods.list_school_free_periods_optimized(all_location_ids, start_date, end_date)
        end)
      end)

    uncached_avg = average(uncached_times)
    IO.puts("Full page load (uncached): #{Float.round(uncached_avg, 2)}ms avg")

    # Warm up all caches
    Locations.list_countries_with_federal_states_cached()
    countries_with_states = Locations.list_countries_with_federal_states_cached()

    all_location_ids =
      Enum.flat_map(countries_with_states, fn {country, federal_states} ->
        [country.id | Enum.map(federal_states, & &1.id)]
      end)

    Periods.list_school_free_periods_cached(all_location_ids, start_date, end_date)

    # Test with full cache
    cached_times =
      Enum.map(1..runs, fn _ ->
        measure_time(fn ->
          countries_with_states = Locations.list_countries_with_federal_states_cached()

          all_location_ids =
            Enum.flat_map(countries_with_states, fn {country, federal_states} ->
              [country.id | Enum.map(federal_states, & &1.id)]
            end)

          _periods =
            Periods.list_school_free_periods_cached(all_location_ids, start_date, end_date)
        end)
      end)

    cached_avg = average(cached_times)
    IO.puts("Full page load (cached): #{Float.round(cached_avg, 2)}ms avg")

    improvement = (uncached_avg - cached_avg) / uncached_avg * 100
    IO.puts("Improvement: #{Float.round(improvement, 1)}% faster")

    %{uncached: uncached_avg, cached: cached_avg, improvement: improvement}
  end

  defp print_cache_stats do
    stats = Cache.get_stats()

    IO.puts("Location Cache:")
    IO.puts("  - Hits: #{stats.location_hits}")
    IO.puts("  - Misses: #{stats.location_misses}")
    IO.puts("  - Hit Rate: #{stats.location_hit_rate}%")

    IO.puts("Query Cache:")
    IO.puts("  - Hits: #{stats.query_hits}")
    IO.puts("  - Misses: #{stats.query_misses}")
    IO.puts("  - Hit Rate: #{stats.query_hit_rate}%")

    IO.puts("Cache Sizes:")
    IO.puts("  - Location Cache: #{stats.cache_sizes.location_cache} entries")
    IO.puts("  - Query Cache: #{stats.cache_sizes.query_cache} entries")

    IO.puts("Total Operations: #{stats.total_operations}")
  end

  defp print_performance_summary(location_results, periods_results, page_load_results) do
    IO.puts("Overall Performance Gains:")
    IO.puts("  - Location Queries: #{Float.round(location_results.improvement, 1)}% faster")
    IO.puts("  - Periods Queries: #{Float.round(periods_results.improvement, 1)}% faster")
    IO.puts("  - Full Page Load: #{Float.round(page_load_results.improvement, 1)}% faster")

    overall_improvement =
      (location_results.improvement + periods_results.improvement + page_load_results.improvement) /
        3

    IO.puts("  - Average Improvement: #{Float.round(overall_improvement, 1)}%")

    # Time savings for a typical page load
    page_load_savings = page_load_results.uncached - page_load_results.cached
    IO.puts("\nTime Savings per Page Load: #{Float.round(page_load_savings, 2)}ms")

    # Extrapolate to daily savings (assuming 1000 page views)
    daily_page_views = 1000
    daily_savings_ms = page_load_savings * daily_page_views
    daily_savings_seconds = daily_savings_ms / 1000

    IO.puts(
      "Estimated Daily Savings (#{daily_page_views} page views): #{Float.round(daily_savings_seconds, 1)} seconds"
    )
  end

  defp print_memory_usage do
    # Get memory usage information
    # Convert words to bytes
    location_cache_memory = :ets.info(:mehr_schulferien_location_cache, :memory) * 8
    query_cache_memory = :ets.info(:mehr_schulferien_query_cache, :memory) * 8

    IO.puts("ETS Cache Memory Usage:")
    IO.puts("  - Location Cache: #{format_bytes(location_cache_memory)}")
    IO.puts("  - Query Cache: #{format_bytes(query_cache_memory)}")
    IO.puts("  - Total Cache Memory: #{format_bytes(location_cache_memory + query_cache_memory)}")
  end

  defp measure_time(fun) do
    start = System.monotonic_time(:microsecond)
    _result = fun.()
    finish = System.monotonic_time(:microsecond)
    # Convert to milliseconds
    (finish - start) / 1000
  end

  defp average(times) do
    Enum.sum(times) / length(times)
  end

  defp format_bytes(bytes) when bytes >= 1024 * 1024 do
    "#{Float.round(bytes / (1024 * 1024), 2)} MB"
  end

  defp format_bytes(bytes) when bytes >= 1024 do
    "#{Float.round(bytes / 1024, 2)} KB"
  end

  defp format_bytes(bytes) do
    "#{bytes} bytes"
  end
end
