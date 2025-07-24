defmodule Mix.Tasks.ImageCache do
  @moduledoc """
  Mix tasks for managing the image cache.

  ## Available commands:

    * `mix image_cache.clear` - Clears the entire image cache
    * `mix image_cache.info` - Shows information about the current cache

  These tasks are useful for deployment scripts and maintenance.
  """

  defmodule Clear do
    @moduledoc """
    Clears the entire image cache.

    ## Usage

        mix image_cache.clear

    This task removes all cached WebP images. It's typically run during
    deployment when the application version changes.
    """

    use Mix.Task

    @shortdoc "Clears the entire image cache"

    def run(_args) do
      Mix.Task.run("app.start")

      Mix.shell().info("Clearing image cache...")

      case MehrSchulferien.ImageCache.clear_cache() do
        :ok ->
          Mix.shell().info("Image cache cleared successfully.")

        error ->
          Mix.shell().error("Failed to clear image cache: #{inspect(error)}")
          exit(:shutdown)
      end
    end
  end

  defmodule Info do
    @moduledoc """
    Shows information about the current image cache.

    ## Usage

        mix image_cache.info

    This task displays the current cache size and other useful statistics.
    """

    use Mix.Task

    @shortdoc "Shows information about the image cache"

    def run(_args) do
      Mix.Task.run("app.start")

      cache_size = MehrSchulferien.ImageCache.cache_size()

      Mix.shell().info("Image Cache Information:")
      Mix.shell().info("  Size: #{format_bytes(cache_size)}")
      Mix.shell().info("  Version: #{Application.spec(:mehr_schulferien, :vsn)}")
    end

    defp format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"
    defp format_bytes(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 2)} KB"

    defp format_bytes(bytes) when bytes < 1024 * 1024 * 1024,
      do: "#{Float.round(bytes / (1024 * 1024), 2)} MB"

    defp format_bytes(bytes), do: "#{Float.round(bytes / (1024 * 1024 * 1024), 2)} GB"
  end
end
