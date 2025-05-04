defmodule MehrSchulferienWeb.PageController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods, BridgeDays}

  def index(conn, %{"number_of_days" => number_of_days}) do
    today = DateHelpers.today_berlin()
    current_year = today.year
    ends_on = Date.add(today, number_of_days)
    days = DateHelpers.create_days(today, number_of_days)
    day_names = DateHelpers.short_days_map()
    months = DateHelpers.get_months_map()
    countries = Enum.map(Locations.list_countries(), &build_country_periods(&1, today, ends_on))

    # Add bridge day information for each federal state
    countries =
      Enum.map(countries, fn country ->
        federal_states =
          Enum.map(country[:federal_states], fn federal_state ->
            # Get years with valid bridge days
            years_with_bridge_days =
              Enum.filter(current_year..(current_year + 2), fn year ->
                BridgeDays.has_bridge_days?(
                  [country[:country].id, federal_state.id],
                  year
                )
              end)

            Map.put(federal_state, :years_with_bridge_days, years_with_bridge_days)
          end)

        Map.put(country, :federal_states, federal_states)
      end)

    render(conn, "index.html",
      countries: countries,
      days: days,
      day_names: day_names,
      months: months,
      current_year: current_year,
      number_of_days: number_of_days
    )
  end

  def index(conn, _params) do
    index(conn, %{"number_of_days" => 84})
  end

  def summer_vacations(conn, _params) do
    today = DateHelpers.today_berlin()
    current_year = today.year
    # 20.6. + 87 Tage = 15.9.
    number_of_days = 87

    # Start der Sommerferien (irgendwo)
    {:ok, today} = Date.from_erl({current_year, 6, 20})

    ends_on = Date.add(today, number_of_days)
    days = DateHelpers.create_days(today, number_of_days)
    day_names = DateHelpers.short_days_map()
    months = DateHelpers.get_months_map()
    countries = Enum.map(Locations.list_countries(), &build_country_periods(&1, today, ends_on))

    render(conn, "summer_vacations.html",
      countries: countries,
      days: days,
      day_names: day_names,
      months: months,
      current_year: current_year,
      number_of_days: number_of_days
    )
  end

  def full_year(conn, _params) do
    index(conn, %{"number_of_days" => 366})
  end

  def developers(conn, _params) do
    render(conn, "developers.html", css_framework: :tailwind)
  end

  def impressum(conn, _params) do
    render(conn, "impressum.html")
  end

  def new(conn, params) do
    # Parse today parameter if present (format: DD.MM.YYYY)
    custom_start_date = 
      case Map.get(params, "today") do
        nil -> nil
        date_str ->
          with [day, month, year] <- String.split(date_str, "."),
               {day, _} <- Integer.parse(day),
               {month, _} <- Integer.parse(month),
               {year, _} <- Integer.parse(year),
               {:ok, date} <- Date.new(year, month, day) do
            date
          else
            _ -> nil
          end
      end
    
    # Parse days parameter if present (integer)
    days_to_display = 
      case Map.get(params, "days") do
        nil -> 90  # Default
        days_str ->
          case Integer.parse(days_str) do
            {days, _} when days > 0 and days <= 365 -> days
            _ -> 90  # Use default if invalid
          end
      end
    
    # If today parameter is present, add noindex flag
    noindex = custom_start_date != nil
    
    today = DateHelpers.today_berlin()
    current_year = today.year
    number_of_days = Map.get(params, "number_of_days", 84) |> ensure_integer()
    
    # Use custom start date or today
    start_date = custom_start_date || today
    
    ends_on = Date.add(start_date, number_of_days)
    days = DateHelpers.create_days(start_date, number_of_days)
    day_names = DateHelpers.short_days_map()
    months = DateHelpers.get_months_map()
    countries = Enum.map(Locations.list_countries(), &build_country_periods(&1, start_date, ends_on))

    # Add bridge day information for each federal state
    countries =
      Enum.map(countries, fn country ->
        federal_states =
          Enum.map(country[:federal_states], fn federal_state ->
            # Get years with valid bridge days
            years_with_bridge_days =
              Enum.filter(current_year..(current_year + 2), fn year ->
                BridgeDays.has_bridge_days?(
                  [country[:country].id, federal_state.id],
                  year
                )
              end)

            Map.put(federal_state, :years_with_bridge_days, years_with_bridge_days)
          end)

        Map.put(country, :federal_states, federal_states)
      end)

    render(conn, "new.html",
      countries: countries,
      days: days,
      day_names: day_names,
      months: months,
      current_year: current_year,
      number_of_days: number_of_days,
      css_framework: :tailwind_new,
      custom_start_date: custom_start_date,
      days_to_display: days_to_display,
      noindex: noindex
    )
  end

  defp build_country_periods(country, today, ends_on) do
    federal_states = country |> Locations.list_federal_states() |> Locations.with_periods()

    periods =
      Enum.reduce(federal_states, [], fn state, acc ->
        acc ++ [{state, Periods.list_school_free_periods([state.id, country.id], today, ends_on)}]
      end)

    %{country: country, federal_states: federal_states, periods: periods}
  end

  defp ensure_integer(value) when is_binary(value), do: String.to_integer(value)
  defp ensure_integer(value) when is_integer(value), do: value
  defp ensure_integer(_), do: 84
end
