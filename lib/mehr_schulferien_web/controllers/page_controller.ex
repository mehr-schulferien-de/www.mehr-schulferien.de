defmodule MehrSchulferienWeb.PageController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods}

  def index(conn, _params) do
    country = Locations.get_country_by_slug!("d")
    federal_states = Locations.list_federal_states(country)
    location_ids = Enum.map(federal_states ++ [country], & &1.id)
    today = Date.utc_today()
    ends_on = Date.add(today, 42)
    periods = Periods.list_school_periods(location_ids, today, ends_on)
    public_periods = Periods.list_all_public_periods(location_ids, today, ends_on)
    days = DateHelpers.create_days(today, 42)
    months = DateHelpers.get_months_map()

    render(conn, "index.html",
      days: days,
      months: months,
      periods: periods,
      public_periods: public_periods
    )
  end
end
