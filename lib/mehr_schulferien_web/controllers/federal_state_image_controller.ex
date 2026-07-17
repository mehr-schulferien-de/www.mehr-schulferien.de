defmodule MehrSchulferienWeb.FederalStateImageController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, ImageCache, ImageConverterResvg, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.Helpers.HandwrittenDateImage

  def handwritten_svg(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    case build_svg(country_slug, federal_state_slug, year, conn) do
      {:ok, svg_content} ->
        conn
        |> put_resp_content_type("image/svg+xml")
        |> put_resp_header("cache-control", "public, max-age=86400")
        |> send_resp(200, svg_content)

      {:error, :no_periods} ->
        conn
        |> put_status(404)
        |> text("No vacation periods found")
    end
  end

  def handwritten_webp(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    # Try to get cached image first
    case ImageCache.get_or_generate_webp(
           cache_key_parts: ["federal_state", country_slug, federal_state_slug, year],
           generator_fn: fn ->
             generate_federal_state_webp(country_slug, federal_state_slug, year, conn)
           end
         ) do
      {:ok, webp_binary} ->
        conn
        |> put_resp_content_type("image/webp")
        |> put_resp_header("cache-control", "public, max-age=86400")
        |> send_resp(200, webp_binary)

      {:error, :no_periods} ->
        conn
        |> put_status(404)
        |> text("No vacation periods found")

      {:error, _reason} ->
        conn
        |> put_status(500)
        |> text("Image conversion failed")
    end
  end

  defp generate_federal_state_webp(country_slug, federal_state_slug, year, conn) do
    case build_svg(country_slug, federal_state_slug, year, conn) do
      {:ok, svg_content} ->
        # Convert SVG to WebP using resvg
        ImageConverterResvg.svg_content_to_webp_binary(svg_content,
          quality: 90,
          width: 1200,
          height: 630
        )

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Loads the locations and vacation data and builds the social media SVG
  # showing all vacation periods for the federal state. Returns
  # {:ok, svg_content} or {:error, :no_periods}.
  defp build_svg(country_slug, federal_state_slug, year, conn) do
    # Load locations
    {federal_state, country} =
      Locations.get_federal_state_and_country_by_slug!(country_slug, federal_state_slug)

    # Get vacation data
    today = DateHelpers.get_today_or_custom_date(conn)
    location_ids = [country.id, federal_state.id]
    data = CH.prepare_show_year_data(location_ids, year, today)

    # Filter to get only multi-day vacation periods (exclude single "schulfrei" days)
    # and sort by start date
    school_vacation_periods =
      data.periods
      |> Enum.filter(fn period ->
        Date.diff(period.ends_on, period.starts_on) > 0
      end)
      |> Enum.sort_by(& &1.starts_on, Date)

    if school_vacation_periods != [] do
      svg_content =
        HandwrittenDateImage.generate_all_vacations_svg_for_social(
          school_vacation_periods,
          federal_state.name,
          String.to_integer(year)
        )

      {:ok, svg_content}
    else
      {:error, :no_periods}
    end
  end
end
