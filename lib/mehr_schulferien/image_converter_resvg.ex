defmodule MehrSchulferien.ImageConverterResvg do
  @moduledoc """
  Converts SVG images to WebP format using Resvg for better font rendering
  and then Mogrify for WebP conversion.
  """

  import Mogrify

  @doc """
  Converts SVG content to WebP format using Resvg and Mogrify.

  First renders SVG to PNG using Resvg (which handles fonts properly),
  then converts PNG to WebP using Mogrify.
  """
  def svg_content_to_webp_binary(svg_content, opts \\ []) do
    width = Keyword.get(opts, :width, 1200)
    height = Keyword.get(opts, :height, 630)
    quality = Keyword.get(opts, :quality, 85)

    # Create temporary files
    temp_svg = Path.join(System.tmp_dir!(), "temp_#{System.unique_integer([:positive])}.svg")
    temp_png = Path.join(System.tmp_dir!(), "temp_#{System.unique_integer([:positive])}.png")

    # Write SVG content to file
    File.write!(temp_svg, svg_content)

    # Configure resvg with font settings
    resvg_opts = [
      width: width,
      height: height,
      font_family: "Comic Sans MS",
      # Add fallback fonts
      sans_serif_family: "Arial",
      cursive_family: "Comic Sans MS",
      # Set DPI for better quality
      dpi: 144
    ]

    # Convert SVG to PNG using resvg
    case Resvg.svg_to_png(temp_svg, temp_png, resvg_opts) do
      :ok ->
        # Clean up SVG file
        File.rm(temp_svg)

        try do
          # Convert PNG to WebP using mogrify
          image =
            open(temp_png)
            |> format("webp")
            |> custom("quality", to_string(quality))
            |> save()

          # Read the WebP file
          webp_binary = File.read!(image.path)

          # Clean up temporary files
          File.rm(temp_png)
          File.rm(image.path)

          {:ok, webp_binary}
        rescue
          e ->
            File.rm(temp_png)
            {:error, Exception.message(e)}
        end

      {:error, reason} ->
        File.rm(temp_svg)
        {:error, "Resvg error: #{inspect(reason)}"}
    end
  end
end
