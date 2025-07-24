defmodule MehrSchulferienWeb.VacationImageController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Repo, Locations, Calendars.DateHelpers, ImageConverterResvg, ImageCache}
  alias MehrSchulferien.Calendars.HolidayOrVacationType
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.Helpers.HandwrittenDateImage
  import Ecto.Query

  def handwritten_svg(conn, %{
        "vacation_slug" => vacation_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    # Load locations
    country = Locations.get_country_by_slug!("d")
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)

    # Extract and load vacation type
    vacation_type_slug = String.replace(vacation_slug, "ferien", "")
    vacation_type_record = get_vacation_type_record(vacation_type_slug)

    if is_nil(vacation_type_record) do
      conn
      |> put_status(404)
      |> text("Not found")
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

        conn
        |> put_resp_content_type("image/svg+xml")
        |> put_resp_header("cache-control", "public, max-age=86400")
        |> send_resp(200, svg_content)
      else
        conn
        |> put_status(404)
        |> text("Vacation period not found")
      end
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
    # Load locations
    country = Locations.get_country_by_slug!("d")
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)

    # Extract and load vacation type
    vacation_type_slug = String.replace(vacation_slug, "ferien", "")
    vacation_type_record = get_vacation_type_record(vacation_type_slug)

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

        # Convert SVG to WebP using resvg
        ImageConverterResvg.svg_content_to_webp_binary(svg_content,
          quality: 90,
          width: 1200,
          height: 630
        )
      else
        {:error, :no_period}
      end
    end
  end

  defp get_vacation_type_record(vacation_type_slug) do
    Repo.one(
      from hvt in HolidayOrVacationType,
        where: hvt.slug == ^vacation_type_slug and hvt.default_is_school_vacation == true
    )
  end
end
