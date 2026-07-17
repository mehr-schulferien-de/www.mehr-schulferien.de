defmodule MehrSchulferienWeb.VacationImageController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Calendars
  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferien.{ImageCache, ImageConverterResvg, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.Helpers.HandwrittenDateImage

  def handwritten_svg(conn, %{
        "vacation_slug" => vacation_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    case build_svg(vacation_slug, federal_state_slug, year, conn) do
      {:ok, svg_content} ->
        conn
        |> put_resp_content_type("image/svg+xml")
        |> put_resp_header("cache-control", "public, max-age=86400")
        |> send_resp(200, svg_content)

      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> text("Not found")

      {:error, :no_period} ->
        conn
        |> put_status(404)
        |> text("Vacation period not found")
    end
  end

  def handwritten_webp(conn, %{
        "vacation_slug" => vacation_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    # Try to get cached image first
    case ImageCache.get_or_generate_webp(
           cache_key_parts: ["vacation", vacation_slug, federal_state_slug, year],
           generator_fn: fn ->
             generate_vacation_webp(vacation_slug, federal_state_slug, year, conn)
           end
         ) do
      {:ok, webp_binary} ->
        conn
        |> put_resp_content_type("image/webp")
        |> put_resp_header("cache-control", "public, max-age=86400")
        |> send_resp(200, webp_binary)

      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> text("Not found")

      {:error, :no_period} ->
        conn
        |> put_status(404)
        |> text("Vacation period not found")

      {:error, _reason} ->
        conn
        |> put_status(500)
        |> text("Image conversion failed")
    end
  end

  defp generate_vacation_webp(vacation_slug, federal_state_slug, year, conn) do
    case build_svg(vacation_slug, federal_state_slug, year, conn) do
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

  # Loads the locations and vacation data and builds the social media SVG.
  # Returns {:ok, svg_content}, {:error, :not_found} if the vacation type
  # does not exist or {:error, :no_period} if there is no matching period.
  defp build_svg(vacation_slug, federal_state_slug, year, conn) do
    # Load locations
    country = Locations.get_country_by_slug!("d")
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)

    # Load vacation type
    vacation_type_record = Calendars.get_vacation_type_by_ferien_slug(vacation_slug)

    if is_nil(vacation_type_record) do
      {:error, :not_found}
    else
      # Get vacation data
      today = DateHelpers.get_today_or_custom_date(conn)
      location_ids = [country.id, federal_state.id]
      data = CH.prepare_show_year_data(location_ids, year, today)

      # Find the specific vacation period
      vacation_period =
        Enum.find(data.periods, fn period ->
          period.holiday_or_vacation_type.name == vacation_type_record.name
        end)

      if vacation_period do
        # Generate SVG for social media
        svg_content =
          HandwrittenDateImage.generate_svg_for_social(
            vacation_period,
            vacation_type_record.colloquial,
            federal_state.name,
            String.to_integer(year),
            data.all_periods
          )

        {:ok, svg_content}
      else
        {:error, :no_period}
      end
    end
  end
end
