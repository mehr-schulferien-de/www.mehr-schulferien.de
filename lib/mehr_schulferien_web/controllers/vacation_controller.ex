defmodule MehrSchulferienWeb.VacationController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.ViewHelpers

  @vacation_types %{
    "sommerferien" => "Sommerferien",
    "osterferien" => "Osterferien",
    "herbstferien" => "Herbstferien",
    "weihnachtsferien" => "Weihnachtsferien",
    "winterferien" => "Winterferien",
    "pfingstferien" => "Pfingstferien"
  }

  # Main vacation display actions
  def sommerferien(conn, params), do: show_vacation(conn, params, "sommerferien")
  def osterferien(conn, params), do: show_vacation(conn, params, "osterferien")
  def herbstferien(conn, params), do: show_vacation(conn, params, "herbstferien")
  def weihnachtsferien(conn, params), do: show_vacation(conn, params, "weihnachtsferien")
  def winterferien(conn, params), do: show_vacation(conn, params, "winterferien")
  def pfingstferien(conn, params), do: show_vacation(conn, params, "pfingstferien")

  # Private functions
  defp show_vacation(
         conn,
         %{"federal_state_slug" => federal_state_slug, "year" => year},
         vacation_type
       ) do
    # Default country is Germany
    country = Locations.get_country_by_slug!("d")
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)

    today = DateHelpers.get_today_or_custom_date(conn)
    location_ids = [country.id, federal_state.id]

    # Get all periods for the state
    data = CH.prepare_show_year_data(location_ids, year, today)

    # Filter for the specific vacation type
    vacation_name = @vacation_types[vacation_type]

    vacation_period =
      Enum.find(data.periods, fn period ->
        period.holiday_or_vacation_type.name == vacation_name
      end)

    # Calculate adjoining_duration for each period
    periods_with_duration =
      Enum.map(data.periods, fn period ->
        days = Date.diff(period.ends_on, period.starts_on) + 1
        effective_duration = ViewHelpers.calculate_effective_duration(period, data.all_periods)
        difference = effective_duration - days
        Map.put(period, :adjoining_duration, difference)
      end)

    # Set 404 if vacation not found
    conn = if vacation_period, do: conn, else: put_status(conn, 404)

    render(
      conn,
      "show.html",
      %{
        country: country,
        federal_state: federal_state,
        vacation_type: vacation_type,
        vacation_name: vacation_name,
        vacation_period: vacation_period,
        periods: periods_with_duration,
        all_periods: data.all_periods,
        public_periods: data.public_periods,
        today: today,
        has_data: not is_nil(vacation_period),
        css_framework: :tailwind_new,
        months: %{
          1 => "Januar",
          2 => "Februar",
          3 => "März",
          4 => "April",
          5 => "Mai",
          6 => "Juni",
          7 => "Juli",
          8 => "August",
          9 => "September",
          10 => "Oktober",
          11 => "November",
          12 => "Dezember"
        },
        year: String.to_integer(year),
        years_with_data: MehrSchulferien.Periods.list_years_with_periods(),
        meta_title_type: :vacation,
        page_title: "#{vacation_name} #{federal_state.name} #{year}"
      }
    )
  end
end
