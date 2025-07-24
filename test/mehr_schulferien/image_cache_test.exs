defmodule MehrSchulferien.ImageCacheTest do
  use ExUnit.Case
  alias MehrSchulferien.ImageCache

  # Fake WebP content for testing
  @test_webp_content <<82, 73, 70, 70, 1, 2, 3, 4>>

  setup do
    # Clear cache before each test
    ImageCache.clear_cache()
    :ok
  end

  describe "get_or_generate_webp/1" do
    test "generates and caches WebP on first call" do
      generator_called = :erlang.unique_integer()

      # First call should invoke generator
      assert {:ok, @test_webp_content} =
               ImageCache.get_or_generate_webp(
                 cache_key_parts: ["test", "part1", "part2", "2025"],
                 generator_fn: fn ->
                   send(self(), {:generator_called, generator_called})
                   {:ok, @test_webp_content}
                 end
               )

      # Verify generator was called
      assert_received {:generator_called, ^generator_called}
    end

    test "returns cached WebP on subsequent calls" do
      # First call to populate cache
      assert {:ok, @test_webp_content} =
               ImageCache.get_or_generate_webp(
                 cache_key_parts: ["test", "cached", "item", "2025"],
                 generator_fn: fn -> {:ok, @test_webp_content} end
               )

      generator_called = :erlang.unique_integer()

      # Second call should use cache, not invoke generator
      assert {:ok, @test_webp_content} =
               ImageCache.get_or_generate_webp(
                 cache_key_parts: ["test", "cached", "item", "2025"],
                 generator_fn: fn ->
                   send(self(), {:generator_called, generator_called})
                   {:ok, @test_webp_content}
                 end
               )

      # Verify generator was NOT called
      refute_received {:generator_called, ^generator_called}
    end

    test "handles generator errors properly" do
      assert {:error, :generation_failed} =
               ImageCache.get_or_generate_webp(
                 cache_key_parts: ["test", "error", "case"],
                 generator_fn: fn -> {:error, :generation_failed} end
               )
    end

    test "includes app version in cache key" do
      # Generate with one set of parts
      assert {:ok, @test_webp_content} =
               ImageCache.get_or_generate_webp(
                 cache_key_parts: ["version", "test", "1"],
                 generator_fn: fn -> {:ok, @test_webp_content} end
               )

      # Verify file was created with version in filename
      cache_dir = Path.join([:code.priv_dir(:mehr_schulferien), "static", "cache", "images"])
      files = File.ls!(cache_dir)

      assert Enum.any?(files, fn file ->
               version = Application.spec(:mehr_schulferien, :vsn) |> to_string()
               # Version dots are replaced with underscores in sanitization
               sanitized_version = String.replace(version, ".", "_")
               String.contains?(file, sanitized_version)
             end)
    end

    test "sanitizes cache key parts" do
      assert {:ok, @test_webp_content} =
               ImageCache.get_or_generate_webp(
                 cache_key_parts: ["special/chars", "test@example", "spaces here"],
                 generator_fn: fn -> {:ok, @test_webp_content} end
               )

      # Verify file was created with sanitized name
      cache_dir = Path.join([:code.priv_dir(:mehr_schulferien), "static", "cache", "images"])
      files = File.ls!(cache_dir)

      assert Enum.any?(files, fn file ->
               # Check that special characters were replaced with underscores
               String.contains?(file, "special_chars") and
                 String.contains?(file, "test_example") and
                 String.contains?(file, "spaces_here")
             end)
    end
  end

  describe "clear_cache/0" do
    test "removes all cached files" do
      # Create some cached files
      ImageCache.get_or_generate_webp(
        cache_key_parts: ["clear", "test", "1"],
        generator_fn: fn -> {:ok, @test_webp_content} end
      )

      ImageCache.get_or_generate_webp(
        cache_key_parts: ["clear", "test", "2"],
        generator_fn: fn -> {:ok, @test_webp_content} end
      )

      # Verify cache has content
      assert ImageCache.cache_size() > 0

      # Clear cache
      assert :ok = ImageCache.clear_cache()

      # Verify cache is empty
      assert ImageCache.cache_size() == 0
    end

    test "handles non-existent cache directory gracefully" do
      # Clear cache first
      ImageCache.clear_cache()

      # Clear again should not error
      assert :ok = ImageCache.clear_cache()
    end
  end

  describe "cache_size/0" do
    test "returns 0 for empty cache" do
      assert ImageCache.cache_size() == 0
    end

    test "returns correct size for cached files" do
      # Create a cached file
      ImageCache.get_or_generate_webp(
        cache_key_parts: ["size", "test"],
        generator_fn: fn -> {:ok, @test_webp_content} end
      )

      # Size should be the byte size of our test content
      assert ImageCache.cache_size() == byte_size(@test_webp_content)
    end

    test "sums multiple cached files" do
      # Create multiple cached files
      ImageCache.get_or_generate_webp(
        cache_key_parts: ["size", "test", "1"],
        generator_fn: fn -> {:ok, @test_webp_content} end
      )

      ImageCache.get_or_generate_webp(
        cache_key_parts: ["size", "test", "2"],
        generator_fn: fn -> {:ok, @test_webp_content} end
      )

      # Size should be twice the byte size of our test content
      assert ImageCache.cache_size() == byte_size(@test_webp_content) * 2
    end
  end
end
