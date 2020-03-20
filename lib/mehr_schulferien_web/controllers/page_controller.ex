defmodule MehrSchulferienWeb.PageController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods}

  def index(conn, _params) do
    country = Locations.get_country_by_slug!("d")
    federal_states = Locations.list_federal_states(country)
    today = Date.utc_today()
    ends_on = Date.add(today, 42)

    periods =
      Enum.reduce(federal_states, [], fn state, acc ->
        acc ++ [{state, Periods.list_school_free_periods([state.id, country.id], today, ends_on)}]
      end)

    days = DateHelpers.create_days(today, 42)
    day_names = DateHelpers.short_days_map()
    months = DateHelpers.get_months_map()

    render(conn, "index.html",
      country: country,
      days: days,
      day_names: day_names,
      federal_states: federal_states,
      months: months,
      periods: periods
    )
  end

  def developers(conn, _params) do
    render(conn, "developers.html")
  end
end
