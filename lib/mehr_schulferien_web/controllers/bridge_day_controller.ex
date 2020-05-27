defmodule MehrSchulferienWeb.BridgeDayController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods}

  def show_within_federal_state(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
    today = DateHelpers.today_berlin()
    current_year = today.year
    {:ok, start_date} = Date.new(current_year, 1, 1)
    {:ok, end_date} = Date.new(current_year, 12, 31)

    public_periods =
      Periods.list_public_everybody_periods([country.id, federal_state.id], start_date, end_date)

    bridge_day_map = Periods.group_by_interval(public_periods)
    days = DateHelpers.create_year(current_year)
    months = DateHelpers.get_months_map()

    assigns = [
      bridge_day_map: bridge_day_map,
      country: country,
      current_year: current_year,
      days: days,
      federal_state: federal_state,
      months: months,
      public_periods: public_periods
    ]

    render(conn, "show_within_federal_state.html", assigns)
  end
end
