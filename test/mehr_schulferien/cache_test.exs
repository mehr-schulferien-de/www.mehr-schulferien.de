defmodule MehrSchulferien.CacheTest do
  use MehrSchulferien.DataCase

  alias MehrSchulferien.Cache

  describe "location cache" do
    test "caches and retrieves location hierarchy" do
      # Cache miss - should return nil
      assert Cache.get_location_hierarchy("test_key") == nil

      # Store test data
      test_data = %{country: %{id: 1, name: "Test"}, states: []}
      Cache.put_location_hierarchy("test_key", test_data)

      # Cache hit - should return stored data
      assert Cache.get_location_hierarchy("test_key") == test_data
    end

    test "cache expires after configured TTL" do
      test_data = %{country: %{id: 1, name: "Test"}, states: []}
      Cache.put_location_hierarchy("test_key", test_data, ttl: 1)

      # Should be cached immediately
      assert Cache.get_location_hierarchy("test_key") == test_data

      # Wait for expiration
      :timer.sleep(1100)

      # Should be expired
      assert Cache.get_location_hierarchy("test_key") == nil
    end

    test "clears specific cache key" do
      test_data = %{country: %{id: 1, name: "Test"}, states: []}
      Cache.put_location_hierarchy("test_key", test_data)

      assert Cache.get_location_hierarchy("test_key") == test_data

      Cache.clear_location_hierarchy("test_key")

      assert Cache.get_location_hierarchy("test_key") == nil
    end

    test "clears all location cache" do
      Cache.put_location_hierarchy("key1", %{data: 1})
      Cache.put_location_hierarchy("key2", %{data: 2})

      assert Cache.get_location_hierarchy("key1") != nil
      assert Cache.get_location_hierarchy("key2") != nil

      Cache.clear_all_location_hierarchies()

      assert Cache.get_location_hierarchy("key1") == nil
      assert Cache.get_location_hierarchy("key2") == nil
    end
  end

  describe "query result cache" do
    test "caches database query results" do
      query_key = "periods_2025_location_1"
      test_results = [%{id: 1, name: "Holiday"}, %{id: 2, name: "Vacation"}]

      # Cache miss
      assert Cache.get_query_result(query_key) == nil

      # Store results
      Cache.put_query_result(query_key, test_results)

      # Cache hit
      assert Cache.get_query_result(query_key) == test_results
    end

    test "query cache respects TTL" do
      query_key = "test_query"
      test_results = [%{id: 1}]

      Cache.put_query_result(query_key, test_results, ttl: 1)
      assert Cache.get_query_result(query_key) == test_results

      :timer.sleep(1100)
      assert Cache.get_query_result(query_key) == nil
    end
  end

  describe "cache statistics" do
    test "tracks cache hits and misses" do
      # Clear stats first
      Cache.clear_stats()

      # Generate some cache activity
      # miss
      Cache.get_location_hierarchy("miss_key")
      Cache.put_location_hierarchy("hit_key", %{data: true})
      # hit
      Cache.get_location_hierarchy("hit_key")
      # miss
      Cache.get_location_hierarchy("miss_key2")

      stats = Cache.get_stats()

      assert stats.location_hits >= 1
      assert stats.location_misses >= 2
      assert stats.total_operations >= 3
    end
  end
end
