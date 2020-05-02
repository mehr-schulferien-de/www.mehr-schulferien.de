defmodule MehrSchulferienWeb.PageController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods}

  def index(conn, _params) do
    country = Locations.get_country_by_slug!("d")
    federal_states = Locations.list_federal_states(country)
    today = DateHelpers.today_berlin()
    ends_on = Date.add(today, 42)

    periods =
      Enum.reduce(federal_states, [], fn state, acc ->
        acc ++ [{state, Periods.list_school_free_periods([state.id, country.id], today, ends_on)}]
      end)

    days = DateHelpers.create_days(today, 42)
    day_names = DateHelpers.short_days_map()
    months = DateHelpers.get_months_map()

    if Date.compare(today, ~D[2020-05-18]) == :lt do
      # For an a/b test this creates a second smaller table which starts
      # on the first next vacation date.
      # TODO: Needs cleaning up after the a/b test.
      today_b = ~D[2020-05-18]
      ends_on_b = Date.add(today_b, 10)

      periods_b =
        Enum.reduce(federal_states, [], fn state, acc ->
          acc ++
            [
              {state,
               Periods.list_school_free_periods([state.id, country.id], today_b, ends_on_b)}
            ]
        end)

      days_b = DateHelpers.create_days(today_b, 10)

      render(conn, "index.html",
        country: country,
        days: days,
        day_names: day_names,
        federal_states: federal_states,
        months: months,
        periods: periods,
        days_b: days_b,
        periods_b: periods_b
      )
    else
      render(conn, "index.html",
        country: country,
        days: days,
        day_names: day_names,
        federal_states: federal_states,
        months: months,
        periods: periods
      )
    end
  end

  def developers(conn, _params) do
    render(conn, "developers.html")
  end

  def impressum(conn, _params) do
    render(conn, "impressum.html")
  end
end
