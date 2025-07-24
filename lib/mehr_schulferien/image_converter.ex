defmodule MehrSchulferien.ImageConverter do
  @moduledoc """
  Converts SVG images to WebP format on the fly using ImageMagick via Mogrify.
  """

  import Mogrify

  @doc """
  Converts an SVG image to WebP format.

  ## Options
    * `:density` - DPI setting for better quality (default: 300)
    * `:quality` - WebP quality 0-100 (default: 85)
    * `:width` - Target width in pixels (optional)
    * `:height` - Target height in pixels (optional)

  ## Examples
      iex> ImageConverter.svg_to_webp("path/to/image.svg")
      {:ok, "path/to/temp/image.webp"}

      iex> ImageConverter.svg_to_webp("path/to/image.svg", density: 600, quality: 90)
      {:ok, "path/to/temp/image.webp"}
  """
  def svg_to_webp(svg_path, opts \\ []) do
    density = Keyword.get(opts, :density, 300)
    quality = Keyword.get(opts, :quality, 85)
    width = Keyword.get(opts, :width)
    height = Keyword.get(opts, :height)

    try do
      image =
        open(svg_path)
        |> custom("density", to_string(density))
        |> custom("background", "white")
        |> custom("font", "Comic-Sans-MS")
        |> format("webp")
        |> custom("quality", to_string(quality))

      image =
        if width && height do
          custom(image, "resize", "#{width}x#{height}!")
        else
          image
        end

      image = save(image)
      {:ok, image.path}
    rescue
      e ->
        {:error, Exception.message(e)}
    end
  end

  @doc """
  Converts SVG content to WebP format from a string.

  ## Examples
      iex> svg_content = "<svg>...</svg>"
      iex> ImageConverter.svg_content_to_webp(svg_content)
      {:ok, "path/to/temp/image.webp"}
  """
  def svg_content_to_webp(svg_content, opts \\ []) do
    # Create a temporary SVG file
    temp_svg_path = Path.join(System.tmp_dir!(), "temp_#{System.unique_integer([:positive])}.svg")

    try do
      File.write!(temp_svg_path, svg_content)
      result = svg_to_webp(temp_svg_path, opts)

      # Clean up the temporary SVG file
      File.rm(temp_svg_path)

      result
    rescue
      e ->
        # Make sure to clean up even if there's an error
        File.rm(temp_svg_path)
        {:error, Exception.message(e)}
    end
  end

  @doc """
  Gets WebP binary data from an SVG file for serving directly.
  """
  def svg_to_webp_binary(svg_path, opts \\ []) do
    case svg_to_webp(svg_path, opts) do
      {:ok, webp_path} ->
        binary = File.read!(webp_path)
        # Clean up the temporary file
        File.rm(webp_path)
        {:ok, binary}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets WebP binary data from SVG content for serving directly.
  """
  def svg_content_to_webp_binary(svg_content, opts \\ []) do
    case svg_content_to_webp(svg_content, opts) do
      {:ok, webp_path} ->
        binary = File.read!(webp_path)
        # Clean up the temporary file
        File.rm(webp_path)
        {:ok, binary}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
