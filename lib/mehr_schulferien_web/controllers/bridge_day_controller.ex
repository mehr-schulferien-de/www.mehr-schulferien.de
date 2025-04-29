defmodule MehrSchulferienWeb.BridgeDayController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods}

  def index_within_federal_state(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
    today = DateHelpers.today_berlin()
    current_year = today.year
    {:ok, last_day} = Date.new(current_year, 12, 31)

    assigns =
      [
        country: country,
        current_year: current_year,
        federal_state: federal_state,
        last_day: last_day,
        today: today
      ] ++ list_bridge_day_data([country.id, federal_state.id], today, last_day)

    render(conn, "index_within_federal_state.html", assigns)
  end

  def show_within_federal_state(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    year = check_year!(year)
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
    {:ok, start_date} = Date.new(year, 1, 1)
    {:ok, end_date} = Date.new(year, 12, 31)

    assigns =
      [country: country, federal_state: federal_state, year: year] ++
        list_bridge_day_data([country.id, federal_state.id], start_date, end_date)

    render(conn, "show_within_federal_state.html", assigns)
  end

  defp list_bridge_day_data(location_ids, start_date, end_date) do
    public_periods = Periods.list_public_everybody_periods(location_ids, start_date, end_date)
    bridge_day_map = Periods.group_by_interval(public_periods)

    bridge_day_proposal_count =
      for num <- 2..5 do
        if bridge_day_map[num] do
          Enum.count(bridge_day_map[num])
        end
      end
      |> Enum.filter(&(!is_nil(&1)))
      |> Enum.sum()

    [
      bridge_day_map: bridge_day_map,
      bridge_day_proposal_count: bridge_day_proposal_count,
      public_periods: public_periods
    ]
  end

  defp check_year!(year) do
    year = String.to_integer(year)
    today = DateHelpers.today_berlin()
    current_year = today.year

    if year in [current_year, current_year + 1, current_year + 2] do
      year
    else
      raise MehrSchulferien.InvalidYearError
    end
  end

  def has_bridge_days?(location_ids, year) do
    {:ok, start_date} = Date.new(year, 1, 1)
    {:ok, end_date} = Date.new(year, 12, 31)
    public_periods = Periods.list_public_everybody_periods(location_ids, start_date, end_date)
    bridge_day_map = Periods.group_by_interval(public_periods)

    Enum.any?(2..5, fn num ->
      if bridge_day_map[num], do: Enum.count(bridge_day_map[num]) > 0, else: false
    end)
  end
end
