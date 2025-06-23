defmodule MehrSchulferien.Cache do
  @moduledoc """
  High-performance ETS-based caching system for location hierarchies and query results.

  This module provides:
  - Location hierarchy caching with configurable TTL
  - Database query result caching
  - Cache statistics and monitoring
  - Automatic cache expiration and cleanup
  """

  use GenServer
  require Logger

  # Cache table names
  @location_cache :mehr_schulferien_location_cache
  @query_cache :mehr_schulferien_query_cache
  @stats_cache :mehr_schulferien_stats_cache

  # Default TTL values (in seconds)
  # 1 hour
  @default_location_ttl 3600
  # 30 minutes
  @default_query_ttl 1800

  ## Public API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets cached location hierarchy data.
  Returns nil if not found or expired.
  """
  def get_location_hierarchy(key) do
    case :ets.lookup(@location_cache, key) do
      [{^key, data, expires_at}] ->
        if :os.system_time(:second) < expires_at do
          increment_stat(:location_hits)
          data
        else
          :ets.delete(@location_cache, key)
          increment_stat(:location_misses)
          nil
        end

      [] ->
        increment_stat(:location_misses)
        nil
    end
  end

  @doc """
  Stores location hierarchy data with optional TTL.
  """
  def put_location_hierarchy(key, data, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_location_ttl)
    expires_at = :os.system_time(:second) + ttl
    :ets.insert(@location_cache, {key, data, expires_at})
    increment_stat(:location_puts)
    :ok
  end

  @doc """
  Clears specific location hierarchy cache entry.
  """
  def clear_location_hierarchy(key) do
    :ets.delete(@location_cache, key)
    :ok
  end

  @doc """
  Clears all location hierarchy cache entries.
  """
  def clear_all_location_hierarchies do
    :ets.delete_all_objects(@location_cache)
    :ok
  end

  @doc """
  Gets cached query results.
  """
  def get_query_result(key) do
    case :ets.lookup(@query_cache, key) do
      [{^key, data, expires_at}] ->
        if :os.system_time(:second) < expires_at do
          increment_stat(:query_hits)
          data
        else
          :ets.delete(@query_cache, key)
          increment_stat(:query_misses)
          nil
        end

      [] ->
        increment_stat(:query_misses)
        nil
    end
  end

  @doc """
  Stores query results with optional TTL.
  """
  def put_query_result(key, data, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_query_ttl)
    expires_at = :os.system_time(:second) + ttl
    :ets.insert(@query_cache, {key, data, expires_at})
    increment_stat(:query_puts)
    :ok
  end

  @doc """
  Gets cache statistics.
  """
  def get_stats do
    location_hits = get_stat(:location_hits)
    location_misses = get_stat(:location_misses)
    query_hits = get_stat(:query_hits)
    query_misses = get_stat(:query_misses)

    %{
      location_hits: location_hits,
      location_misses: location_misses,
      location_hit_rate: calculate_hit_rate(location_hits, location_misses),
      query_hits: query_hits,
      query_misses: query_misses,
      query_hit_rate: calculate_hit_rate(query_hits, query_misses),
      total_operations: location_hits + location_misses + query_hits + query_misses,
      cache_sizes: %{
        location_cache: :ets.info(@location_cache, :size),
        query_cache: :ets.info(@query_cache, :size)
      }
    }
  end

  @doc """
  Clears all cache statistics.
  """
  def clear_stats do
    :ets.delete_all_objects(@stats_cache)
    :ok
  end

  @doc """
  Helper function to cache expensive location operations.
  """
  def cached_location_operation(cache_key, fun, opts \\ []) do
    case get_location_hierarchy(cache_key) do
      nil ->
        result = fun.()
        put_location_hierarchy(cache_key, result, opts)
        result

      cached_result ->
        cached_result
    end
  end

  @doc """
  Helper function to cache expensive query operations.
  """
  def cached_query_operation(cache_key, fun, opts \\ []) do
    case get_query_result(cache_key) do
      nil ->
        result = fun.()
        put_query_result(cache_key, result, opts)
        result

      cached_result ->
        cached_result
    end
  end

  ## GenServer Callbacks

  @impl true
  def init(_opts) do
    # Create ETS tables
    :ets.new(@location_cache, [:set, :public, :named_table, read_concurrency: true])
    :ets.new(@query_cache, [:set, :public, :named_table, read_concurrency: true])
    :ets.new(@stats_cache, [:set, :public, :named_table, write_concurrency: true])

    # Schedule periodic cleanup
    schedule_cleanup()

    Logger.info("MehrSchulferien.Cache started successfully")
    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired_entries()
    schedule_cleanup()
    {:noreply, state}
  end

  ## Private Functions

  defp increment_stat(key) do
    :ets.update_counter(@stats_cache, key, 1, {key, 0})
  end

  defp get_stat(key) do
    case :ets.lookup(@stats_cache, key) do
      [{^key, count}] -> count
      [] -> 0
    end
  end

  defp calculate_hit_rate(hits, misses) do
    total = hits + misses
    if total > 0, do: Float.round(hits / total * 100, 2), else: 0.0
  end

  defp schedule_cleanup do
    # Run cleanup every 5 minutes
    Process.send_after(self(), :cleanup, 5 * 60 * 1000)
  end

  defp cleanup_expired_entries do
    current_time = :os.system_time(:second)

    # Cleanup location cache
    location_expired =
      :ets.select(@location_cache, [
        {{:"$1", :"$2", :"$3"}, [{:<, :"$3", current_time}], [:"$1"]}
      ])

    Enum.each(location_expired, fn key ->
      :ets.delete(@location_cache, key)
    end)

    # Cleanup query cache  
    query_expired =
      :ets.select(@query_cache, [
        {{:"$1", :"$2", :"$3"}, [{:<, :"$3", current_time}], [:"$1"]}
      ])

    Enum.each(query_expired, fn key ->
      :ets.delete(@query_cache, key)
    end)

    if length(location_expired) > 0 or length(query_expired) > 0 do
      Logger.debug(
        "Cache cleanup: removed #{length(location_expired)} location entries, #{length(query_expired)} query entries"
      )
    end
  end
end
