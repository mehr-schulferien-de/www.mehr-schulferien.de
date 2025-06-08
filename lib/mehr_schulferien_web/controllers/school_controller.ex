defmodule MehrSchulferienWeb.SchoolController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.SchoolView

  def show_year(conn, %{
        "country_slug" => country_slug,
        "school_slug" => school_slug,
        "year" => year
      }) do
    %{country: country, federal_state: federal_state, county: county, city: city, school: school} =
      Locations.show_school_to_country_map(country_slug, school_slug)

    # Convert year to integer
    year = String.to_integer(year)

    # Get current year for reference
    current_year = Date.utc_today().year
    today = DateHelpers.get_today_or_custom_date(conn)

    # Define the range of years to check (current year and 3 years in each direction)
    check_years = (year - 3)..(year + 3) |> Enum.to_list()

    # Get vacation periods for the entire range with a single query
    range_start = Date.from_erl!({Enum.min(check_years), 1, 1})
    range_end = Date.from_erl!({Enum.max(check_years), 12, 31})
    location_ids = [country.id, federal_state.id, county.id, city.id, school.id]

    all_periods =
      MehrSchulferien.Periods.list_school_vacation_periods(
        location_ids,
        range_start,
        range_end
      )

    # Group periods by year
    periods_by_year =
      Enum.group_by(all_periods, fn period ->
        period.starts_on.year
      end)

    # Determine which years have data
    years_with_data =
      Enum.filter(check_years, fn check_year ->
        case Map.get(periods_by_year, check_year) do
          nil -> false
          periods -> length(periods) > 0
        end
      end)
      |> Enum.sort()

    # Get periods for the current year plus next year until July 31st
    current_year_periods = Map.get(periods_by_year, year, [])
    next_year_periods = Map.get(periods_by_year, year + 1, [])

    # Filter next year periods to include only those until July 31st
    next_year_july_periods =
      Enum.filter(next_year_periods, fn period ->
        {:ok, july_end_date} = Date.new(year + 1, 7, 31)
        Date.compare(period.starts_on, july_end_date) in [:lt, :eq]
      end)

    # Combine current year periods with filtered next year periods
    extended_periods = current_year_periods ++ next_year_july_periods

    # Check if data exists for the requested period
    has_data = length(extended_periods) > 0

    # Get public holiday periods for the year and next year until July
    {:ok, year_start} = Date.new(year, 1, 1)
    {:ok, next_year_july_end} = Date.new(year + 1, 7, 31)

    public_periods =
      MehrSchulferien.Periods.list_public_periods(
        location_ids,
        year_start,
        next_year_july_end
      )

    all_periods_for_calculation = extended_periods ++ public_periods

    # Calculate adjoining_duration for each period
    # This ensures display values reflect the current calculation
    extended_periods =
      Enum.map(extended_periods, fn period ->
        days = Date.diff(period.ends_on, period.starts_on) + 1

        effective_duration =
          SchoolView.calculate_effective_duration(period, all_periods_for_calculation)

        difference = effective_duration - days

        # Just set the value in the struct for rendering
        # No database update since it's a virtual field
        Map.put(period, :adjoining_duration, difference)
      end)

    # Set the appropriate status code based on data availability
    conn = if has_data, do: conn, else: put_status(conn, 404)

    # Get FAQ data
    faq_data = CH.list_faq_data(location_ids, today)

    # Get nearby schools
    nearby_schools = Locations.list_nearby_schools(school, 3000)

    # Calculate next_schulferien_periods (up to 3 periods) for the FAQ
    sorted_periods =
      Enum.sort(
        public_periods ++ extended_periods,
        &(Date.compare(&1.starts_on, &2.starts_on) == :lt)
      )

    next_schulferien_periods = MehrSchulferien.Periods.next_periods(sorted_periods, 3)

    # Months map for formatting
    months = %{
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
    }

    render(
      conn,
      "show_year.html",
      %{
        country: country,
        federal_state: federal_state,
        county: county,
        city: city,
        school: school,
        year: year,
        years_with_data: years_with_data,
        current_year: current_year,
        periods: extended_periods,
        public_periods: public_periods,
        all_periods: all_periods_for_calculation,
        has_data: has_data,
        css_framework: :tailwind_new,
        today: today,
        school_periods: extended_periods,
        next_schulferien_periods: next_schulferien_periods,
        months: months,
        nearby_schools: nearby_schools
      }
      |> Map.merge(Map.new(faq_data))
    )
  end

  def show(conn, %{"country_slug" => country_slug, "school_slug" => school_slug}) do
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year

    redirect(conn,
      to:
        Routes.school_path(
          conn,
          :show_year,
          country_slug,
          school_slug,
          current_year
        )
    )
  end
end
