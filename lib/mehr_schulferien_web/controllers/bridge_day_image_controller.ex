defmodule MehrSchulferienWeb.BridgeDayImageController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{ImageCache, ImageConverterResvg, Locations, Periods}
  alias MehrSchulferienWeb.BridgeDayView
  alias MehrSchulferienWeb.Helpers.HandwrittenBridgeDayImage

  def handwritten_svg(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    case validate_and_load_data(country_slug, federal_state_slug, year) do
      {:ok, data} ->
        %{
          federal_state: federal_state,
          year_int: year_int,
          bridge_day_map: bridge_day_map,
          public_periods: public_periods
        } = data

        # Generate SVG showing normal bridge days
        svg_content =
          HandwrittenBridgeDayImage.generate_svg_for_social(
            bridge_day_map,
            federal_state.name,
            year_int,
            public_periods
          )

        conn
        |> put_resp_content_type("image/svg+xml")
        |> put_resp_header("cache-control", "public, max-age=86400")
        |> send_resp(200, svg_content)

      {:error, _reason} ->
        conn
        |> put_status(:not_found)
        |> text("Not found")
    end
  end

  def handwritten_webp(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    # Try to get cached image first
    case ImageCache.get_or_generate_webp(
           cache_key_parts: ["bridge_day", country_slug, federal_state_slug, year],
           generator_fn: fn ->
             generate_bridge_day_webp(country_slug, federal_state_slug, year, conn)
           end
         ) do
      {:ok, webp_content} ->
        send_cached_webp(conn, webp_content)

      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> text("Error generating image")
    end
  end

  defp validate_and_load_data(country_slug, federal_state_slug, year_str) do
    with {:ok, year_int} <- parse_year(year_str),
         country <- Locations.get_country_by_slug!(country_slug),
         federal_state <- Locations.get_federal_state_by_slug!(federal_state_slug, country),
         true <- has_bridge_days?([country.id, federal_state.id], year_int),
         {:ok, start_date} <- Date.new(year_int, 1, 1),
         {:ok, end_date} <- Date.new(year_int, 12, 31) do
      # Get bridge day data
      location_ids = [country.id, federal_state.id]
      public_periods = Periods.list_public_everybody_periods(location_ids, start_date, end_date)
      bridge_day_map = Periods.group_by_interval(public_periods)

      # Filter bridge days to only include those that meet minimum gain requirements
      filtered_bridge_day_map =
        for {num, bridge_days} <- bridge_day_map, into: %{} do
          filtered_bridge_days =
            bridge_days
            |> Enum.filter(fn bridge_day ->
              all_periods = Periods.list_periods_with_bridge_day(public_periods, bridge_day)
              BridgeDayView.meets_minimum_gain?(bridge_day, all_periods)
            end)

          {num, filtered_bridge_days}
        end

      {:ok,
       %{
         country: country,
         federal_state: federal_state,
         year_int: year_int,
         bridge_day_map: filtered_bridge_day_map,
         public_periods: public_periods
       }}
    else
      false -> {:error, :no_bridge_days}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :unknown}
    end
  end

  defp parse_year(year_str) do
    case Integer.parse(year_str) do
      {year, ""} ->
        current_year = Date.utc_today().year

        if year in (current_year - 5)..(current_year + 3) do
          {:ok, year}
        else
          {:error, :invalid_year}
        end

      _ ->
        {:error, :invalid_year}
    end
  end

  defp has_bridge_days?(location_ids, year) do
    MehrSchulferienWeb.BridgeDayController.has_bridge_days?(location_ids, year)
  end

  defp send_cached_webp(conn, webp_content) do
    conn
    |> put_resp_content_type("image/webp")
    |> put_resp_header("cache-control", "public, max-age=86400")
    |> send_resp(200, webp_content)
  end

  defp generate_bridge_day_webp(country_slug, federal_state_slug, year, _conn) do
    case validate_and_load_data(country_slug, federal_state_slug, year) do
      {:ok, data} ->
        %{
          federal_state: federal_state,
          year_int: year_int,
          bridge_day_map: bridge_day_map,
          public_periods: public_periods
        } = data

        # Generate SVG
        svg_content =
          HandwrittenBridgeDayImage.generate_svg_for_social(
            bridge_day_map,
            federal_state.name,
            year_int,
            public_periods
          )

        # Convert to WebP
        ImageConverterResvg.svg_content_to_webp_binary(svg_content)

      {:error, _reason} ->
        {:error, :generation_failed}
    end
  end
end
