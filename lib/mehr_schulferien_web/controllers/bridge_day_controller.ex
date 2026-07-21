defmodule MehrSchulferienWeb.BridgeDayController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH

  @doc """
  National overview: all federal states with their bridge day opportunities
  for one year. Targets the Germany-wide "brückentage <jahr>" queries that
  previously landed on individual state pages.
  """
  def index_country(conn, %{"country_slug" => country_slug, "year" => year}) do
    today = DateHelpers.get_today_or_custom_date(conn)

    with {:ok, country} <- fetch_country(country_slug),
         {:ok, year_int} <- check_year(year) do
      if year_int < today.year do
        # Past bridge days are worthless; consolidate into the current year.
        conn
        |> put_status(:moved_permanently)
        |> redirect(to: ~p"/brueckentage/#{country.slug}/#{today.year}")
      else
        render_country_overview(conn, country, year_int)
      end
    else
      {:error, :not_found} ->
        CH.render_not_found_or_empty_database(conn)

      _ ->
        conn = Plug.Conn.put_status(conn, :not_found)
        raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router
    end
  end

  defp render_country_overview(conn, country, year_int) do
    states_with_counts =
      country
      |> Locations.list_federal_states()
      |> Enum.map(fn federal_state ->
        {federal_state, bridge_day_proposal_count([country.id, federal_state.id], year_int)}
      end)

    total_count = states_with_counts |> Enum.map(&elem(&1, 1)) |> Enum.sum()

    if total_count == 0 do
      conn = Plug.Conn.put_status(conn, :not_found)
      raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router
    else
      render(conn, "index_country.html",
        country: country,
        year: year_int,
        states_with_counts: states_with_counts,
        total_count: total_count
      )
    end
  end

  defp bridge_day_proposal_count(location_ids, year) do
    {:ok, start_date} = Date.new(year, 1, 1)
    {:ok, end_date} = Date.new(year, 12, 31)
    public_periods = Periods.list_public_everybody_periods(location_ids, start_date, end_date)
    bridge_day_map = Periods.group_by_interval(public_periods)

    2..5
    |> Enum.map(fn num ->
      bridge_day_map
      |> Map.get(num, [])
      |> Enum.count(fn bridge_day ->
        all_periods = Periods.list_periods_with_bridge_day(public_periods, bridge_day)
        MehrSchulferien.BridgeDayCalculations.meets_minimum_gain?(bridge_day, all_periods)
      end)
    end)
    |> Enum.sum()
  end

  @doc """
  Evergreen bridge day page for one state: a stable year-less URL showing
  the current year's opportunities plus links to the year pages, mirroring
  the evergreen state pages that rank for head terms.
  """
  def index_within_federal_state(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year

    with {:ok, country} <- fetch_country(country_slug),
         {:ok, federal_state} <- fetch_federal_state(country, federal_state_slug) do
      location_ids = [country.id, federal_state.id]

      if Enum.any?(current_year..(current_year + 2), &has_bridge_days?(location_ids, &1)) do
        {:ok, start_date} = Date.new(current_year, 1, 1)
        {:ok, end_date} = Date.new(current_year, 12, 31)

        assigns =
          [country: country, federal_state: federal_state, current_year: current_year] ++
            list_bridge_day_data(location_ids, start_date, end_date)

        render(conn, "index_within_federal_state.html", assigns)
      else
        conn = Plug.Conn.put_status(conn, :not_found)
        raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router
      end
    else
      {:error, :not_found} ->
        CH.render_not_found_or_empty_database(conn)
    end
  end

  def show_within_federal_state(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    today = DateHelpers.get_today_or_custom_date(conn)

    with {:ok, country} <- fetch_country(country_slug),
         {:ok, federal_state} <- fetch_federal_state(country, federal_state_slug),
         {:ok, year_int} <- check_year(year) do
      if year_int < today.year do
        # Bridge day opportunities are worthless once the year is over;
        # consolidate past-year URLs (and links to them) into the current
        # year instead of serving 404s.
        conn
        |> put_status(:moved_permanently)
        |> redirect(
          to: ~p"/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/#{today.year}"
        )
      else
        render_bridge_days(conn, country, federal_state, year_int)
      end
    else
      {:error, :not_found} ->
        CH.render_not_found_or_empty_database(conn)

      _ ->
        conn = Plug.Conn.put_status(conn, :not_found)
        raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router
    end
  end

  defp render_bridge_days(conn, country, federal_state, year_int) do
    with {:ok, start_date} <- Date.new(year_int, 1, 1),
         {:ok, end_date} <- Date.new(year_int, 12, 31),
         true <- has_bridge_days?([country.id, federal_state.id], year_int) do
      assigns =
        [country: country, federal_state: federal_state, year: year_int] ++
          list_bridge_day_data([country.id, federal_state.id], start_date, end_date)

      render(conn, "show_within_federal_state.html", assigns)
    else
      _ ->
        conn = Plug.Conn.put_status(conn, :not_found)
        raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router
    end
  end

  defp fetch_country(country_slug), do: CH.fetch_country(country_slug)

  defp fetch_federal_state(country, federal_state_slug),
    do: CH.fetch_federal_state(federal_state_slug, country)

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
            MehrSchulferien.BridgeDayCalculations.meets_minimum_gain?(bridge_day, all_periods)
          end)

        {num, filtered_bridge_days}
      end

    bridge_day_proposal_count =
      2..5
      |> Enum.map(&length(Map.get(filtered_bridge_day_map, &1, [])))
      |> Enum.sum()

    [
      bridge_day_map: filtered_bridge_day_map,
      bridge_day_proposal_count: bridge_day_proposal_count,
      public_periods: public_periods
    ]
  end

  defp check_year(year), do: CH.check_year(year)

  def has_bridge_days?(location_ids, year) do
    {:ok, start_date} = Date.new(year, 1, 1)
    {:ok, end_date} = Date.new(year, 12, 31)
    public_periods = Periods.list_public_everybody_periods(location_ids, start_date, end_date)
    bridge_day_map = Periods.group_by_interval(public_periods)

    # Check for at least one bridge day that meets the minimum gain requirement
    Enum.any?(2..5, fn num ->
      bridge_day_map
      |> Map.get(num, [])
      |> Enum.any?(fn bridge_day ->
        all_periods = Periods.list_periods_with_bridge_day(public_periods, bridge_day)
        MehrSchulferien.BridgeDayCalculations.meets_minimum_gain?(bridge_day, all_periods)
      end)
    end)
  end
end
