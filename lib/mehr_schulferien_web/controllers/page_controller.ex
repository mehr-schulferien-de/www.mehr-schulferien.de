defmodule MehrSchulferienWeb.PageController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods}

  def index(conn, _params) do
    today = DateHelpers.today_berlin()
    current_year = today.year
    ends_on = Date.add(today, 42)
    days = DateHelpers.create_days(today, 42)
    day_names = DateHelpers.short_days_map()
    months = DateHelpers.get_months_map()
    countries = Enum.map(Locations.list_countries(), &build_country_periods(&1, today, ends_on))

    render(conn, "index.html",
      countries: countries,
      days: days,
      day_names: day_names,
      months: months,
      current_year: current_year
    )
  end

  def developers(conn, _params) do
    render(conn, "developers.html")
  end

  def impressum(conn, _params) do
    render(conn, "impressum.html")
  end

  defp build_country_periods(country, today, ends_on) do
    federal_states = country |> Locations.list_federal_states() |> Locations.with_periods()

    periods =
      Enum.reduce(federal_states, [], fn state, acc ->
        acc ++ [{state, Periods.list_school_free_periods([state.id, country.id], today, ends_on)}]
      end)

    %{country: country, federal_states: federal_states, periods: periods}
  end
end
