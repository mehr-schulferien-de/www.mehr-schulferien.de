defmodule MehrSchulferienWeb.CountryController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods}

  def show(conn, %{"country_slug" => country_slug}) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_states = Locations.list_federal_states(country)
    current_year = DateHelpers.today_berlin().year
    {:ok, start_date} = Date.new(current_year, 1, 1)
    {:ok, end_date} = Date.new(current_year, 12, 31)

    periods =
      Enum.reduce(
        federal_states,
        %{},
        &Map.put(&2, &1.name, list_year_periods(country, &1, start_date, end_date))
      )

    months = DateHelpers.get_months_map()

    render(conn, "show.html",
      country: country,
      current_year: current_year,
      federal_states: federal_states,
      months: months,
      periods: periods,
      css_framework: :tailwind_new
    )
  end

  defp list_year_periods(country, federal_state, start_date, end_date) do
    periods =
      Periods.list_school_vacation_periods([country.id, federal_state.id], start_date, end_date)

    Enum.filter(periods, &(&1.starts_on.year == start_date.year))
  end
end
