defmodule MehrSchulferienWeb.FederalStateImageController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Locations, Calendars.DateHelpers, ImageConverterResvg}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.Helpers.HandwrittenDateImage

  def handwritten_svg(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
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

    if length(school_vacation_periods) > 0 do
      # Generate SVG showing all vacation periods for the federal state
      svg_content =
        HandwrittenDateImage.generate_all_vacations_svg_for_social(
          school_vacation_periods,
          federal_state.name,
          String.to_integer(year)
        )

      conn
      |> put_resp_content_type("image/svg+xml")
      |> put_resp_header("cache-control", "public, max-age=86400")
      |> send_resp(200, svg_content)
    else
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

    if length(school_vacation_periods) > 0 do
      # Generate SVG showing all vacation periods for the federal state
      svg_content =
        HandwrittenDateImage.generate_all_vacations_svg_for_social(
          school_vacation_periods,
          federal_state.name,
          String.to_integer(year)
        )

      # Convert SVG to WebP on the fly using resvg
      case ImageConverterResvg.svg_content_to_webp_binary(svg_content,
             quality: 90,
             width: 1200,
             height: 630
           ) do
        {:ok, webp_binary} ->
          conn
          |> put_resp_content_type("image/webp")
          |> put_resp_header("cache-control", "public, max-age=86400")
          |> send_resp(200, webp_binary)

        {:error, _reason} ->
          conn
          |> put_status(500)
          |> text("Image conversion failed")
      end
    else
      conn
      |> put_status(404)
      |> text("No vacation periods found")
    end
  end
end