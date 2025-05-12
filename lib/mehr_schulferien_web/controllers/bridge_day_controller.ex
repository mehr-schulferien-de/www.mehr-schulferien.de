defmodule MehrSchulferienWeb.BridgeDayController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods}
  alias MehrSchulferienWeb.BridgeDayView

  def index_within_federal_state(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year

    conn
    |> redirect(
      to:
        Routes.bridge_day_path(
          conn,
          :show_within_federal_state,
          country_slug,
          federal_state_slug,
          current_year
        ),
      status: :temporary_redirect
    )
  end

  def show_within_federal_state(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    with {:ok, year} <- check_year(conn, year),
         country <- Locations.get_country_by_slug!(country_slug),
         federal_state <- Locations.get_federal_state_by_slug!(federal_state_slug, country),
         {:ok, start_date} <- Date.new(year, 1, 1),
         {:ok, end_date} <- Date.new(year, 12, 31),
         true <- has_bridge_days?([country.id, federal_state.id], year) do
      assigns =
        [country: country, federal_state: federal_state, year: year] ++
          list_bridge_day_data([country.id, federal_state.id], start_date, end_date)

      render(conn, "show_within_federal_state.html", assigns ++ [css_framework: :tailwind_new])
    else
      # No bridge days for this year
      false ->
        conn = Plug.Conn.put_status(conn, :not_found)
        raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router

      {:error, :invalid_year} ->
        conn = Plug.Conn.put_status(conn, :not_found)
        raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router

      _ ->
        conn = Plug.Conn.put_status(conn, :not_found)
        raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router
    end
  end

  defp list_bridge_day_data(location_ids, start_date, end_date) do
    public_periods = Periods.list_public_everybody_periods(location_ids, start_date, end_date)
    bridge_day_map = Periods.group_by_interval(public_periods)

    # Filter the bridge days to only include those that meet the minimum gain requirements
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

    bridge_day_proposal_count =
      for num <- 2..5 do
        if filtered_bridge_day_map[num] do
          Enum.count(filtered_bridge_day_map[num])
        end
      end
      |> Enum.filter(&(!is_nil(&1)))
      |> Enum.sum()

    [
      bridge_day_map: filtered_bridge_day_map,
      bridge_day_proposal_count: bridge_day_proposal_count,
      public_periods: public_periods
    ]
  end

  defp check_year(_conn, year) do
    case Integer.parse(year) do
      {year, ""} ->
        # Use the actual now date for validation range, not the custom date
        current_year = Date.utc_today().year

        # Allow a wider range of years, especially past years (5 years back, 3 years forward)
        if year in (current_year - 5)..(current_year + 3) do
          {:ok, year}
        else
          {:error, :invalid_year}
        end

      _ ->
        {:error, :invalid_year}
    end
  end

  def has_bridge_days?(location_ids, year) do
    {:ok, start_date} = Date.new(year, 1, 1)
    {:ok, end_date} = Date.new(year, 12, 31)
    public_periods = Periods.list_public_everybody_periods(location_ids, start_date, end_date)
    bridge_day_map = Periods.group_by_interval(public_periods)

    # Check for at least one bridge day that meets the minimum gain requirement
    Enum.any?(2..5, fn num ->
      if bridge_day_map[num] do
        bridge_day_map[num]
        |> Enum.any?(fn bridge_day ->
          all_periods = Periods.list_periods_with_bridge_day(public_periods, bridge_day)
          BridgeDayView.meets_minimum_gain?(bridge_day, all_periods)
        end)
      else
        false
      end
    end)
  end
end
