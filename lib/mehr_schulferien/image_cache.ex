defmodule MehrSchulferien.ImageCache do
  @moduledoc """
  Handles caching of generated WebP images to avoid regenerating them on every request.
  Cache files are stored in the filesystem and tied to the application version.
  """

  @doc """
  Gets a cached WebP image or generates and caches it.

  The cache key is generated from the provided parameters and the current app version.
  If the cached file exists and is valid, it returns the cached binary.
  Otherwise, it calls the generator function and caches the result.

  ## Options
    * `:cache_key_parts` - List of strings/atoms to build the cache key
    * `:generator_fn` - Function that generates the WebP binary when cache miss

  ## Examples
      ImageCache.get_or_generate_webp(
        cache_key_parts: ["vacation", vacation_slug, federal_state_slug, year],
        generator_fn: fn -> generate_vacation_webp(params) end
      )
  """
  def get_or_generate_webp(opts) do
    cache_key_parts = Keyword.fetch!(opts, :cache_key_parts)
    generator_fn = Keyword.fetch!(opts, :generator_fn)

    cache_path = build_cache_path(cache_key_parts)

    case read_cached_file(cache_path) do
      {:ok, binary} ->
        {:ok, binary}

      {:error, :not_found} ->
        case generator_fn.() do
          {:ok, webp_binary} ->
            write_cache_file(cache_path, webp_binary)
            {:ok, webp_binary}

          error ->
            error
        end
    end
  end

  @doc """
  Clears the entire image cache.
  This should be called when deploying a new version or when cache needs to be invalidated.
  """
  def clear_cache do
    cache_dir = get_cache_dir()

    if File.exists?(cache_dir) do
      File.rm_rf!(cache_dir)
    end

    :ok
  end

  @doc """
  Gets the size of the cache directory in bytes.
  """
  def cache_size do
    cache_dir = get_cache_dir()

    if File.exists?(cache_dir) do
      cache_dir
      |> File.ls!()
      |> Enum.map(fn file ->
        path = Path.join(cache_dir, file)
        stat = File.stat!(path)
        stat.size
      end)
      |> Enum.sum()
    else
      0
    end
  end

  # Private functions

  defp build_cache_path(parts) do
    # Include app version in the cache key to invalidate on deploy
    version = Application.spec(:mehr_schulferien, :vsn) |> to_string()

    # Build a safe filename from the parts
    filename_parts = [version | parts]

    filename =
      filename_parts
      |> Enum.map_join("-", &to_string/1)
      |> String.replace(~r/[^a-zA-Z0-9\-_]/, "_")

    Path.join(get_cache_dir(), "#{filename}.webp")
  end

  defp get_cache_dir do
    Path.join([:code.priv_dir(:mehr_schulferien), "static", "cache", "images"])
  end

  defp read_cached_file(path) do
    case File.read(path) do
      {:ok, binary} -> {:ok, binary}
      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp write_cache_file(path, binary) do
    # Ensure the cache directory exists
    dir = Path.dirname(path)
    File.mkdir_p!(dir)

    # Write the file
    File.write!(path, binary)
  end
end
