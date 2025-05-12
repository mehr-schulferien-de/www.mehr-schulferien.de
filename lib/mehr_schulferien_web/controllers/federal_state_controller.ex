defmodule MehrSchulferienWeb.FederalStateController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.FederalStateView

  @digits ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

  def show(_conn, %{"modus" => _}) do
    raise MehrSchulferien.InvalidQueryParamsError
  end

  def show(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => <<first::binary-size(1)>> <> _ = id
      })
      when first in @digits do
    location = Locations.get_federal_state!(id)
    redirect(conn, to: Routes.federal_state_path(conn, :show, country_slug, location.slug))
  end

  def show(conn, %{"country_slug" => country_slug, "federal_state_slug" => federal_state_slug}) do
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year

    redirect(conn,
      to:
        Routes.federal_state_path(
          conn,
          :show_year,
          country_slug,
          federal_state_slug,
          current_year
        ),
      status: :temporary_redirect
    )
  end

  def show_year(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    {federal_state, country} =
      Locations.get_federal_state_and_country_by_slug!(country_slug, federal_state_slug)

    # Check if year is "brueckentage" and handle special case
    if year == "brueckentage" do
      conn = Plug.Conn.put_status(conn, :not_found)
      raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router
    end

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
    location_ids = [country.id, federal_state.id]

    all_periods =
      MehrSchulferien.Periods.Query.list_school_vacation_periods(
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

    # Get just the periods for the current year
    current_year_periods = Map.get(periods_by_year, year, [])

    # Check if data exists for the requested year
    has_data = length(current_year_periods) > 0

    # Get public holiday periods for the year
    {:ok, year_start} = Date.new(year, 1, 1)
    {:ok, year_end} = Date.new(year, 12, 31)

    public_periods =
      MehrSchulferien.Periods.Query.list_public_periods(
        location_ids,
        year_start,
        year_end
      )

    # Combine school vacation periods with public holiday periods for calculations
    all_periods_for_calculation = current_year_periods ++ public_periods

    # Calculate adjoining_duration for each period
    # This ensures display values reflect the current calculation
    current_year_periods =
      Enum.map(current_year_periods, fn period ->
        days = Date.diff(period.ends_on, period.starts_on) + 1

        effective_duration =
          FederalStateView.calculate_effective_duration(period, all_periods_for_calculation)

        difference = effective_duration - days

        # Just set the value in the struct for rendering
        # No database update since it's a virtual field
        Map.put(period, :adjoining_duration, difference)
      end)

    # Set the appropriate status code based on data availability
    conn = if has_data, do: conn, else: put_status(conn, 404)

    # Get FAQ data
    faq_data = CH.list_faq_data(location_ids, today)

    # Calculate next_schulferien_periods (up to 3 periods) for the FAQ
    sorted_periods =
      Enum.sort(
        public_periods ++ current_year_periods,
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
        year: year,
        years_with_data: years_with_data,
        current_year: current_year,
        periods: current_year_periods,
        public_periods: public_periods,
        all_periods: all_periods_for_calculation,
        has_data: has_data,
        css_framework: :tailwind_new,
        today: today,
        school_periods: current_year_periods,
        next_schulferien_periods: next_schulferien_periods,
        months: months
      }
      |> Map.merge(Map.new(faq_data))
    )
  end

  def county_show(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)

    # Use the optimized function to get counties with cities having schools
    counties_with_cities = Locations.list_counties_with_cities_having_schools(federal_state)

    location_ids = [country.id, federal_state.id]
    today = DateHelpers.get_today_or_custom_date(conn)

    assigns =
      [
        counties_with_cities: counties_with_cities,
        country: country,
        federal_state: federal_state,
        css_framework: :tailwind_new
      ] ++
        CH.list_period_data(location_ids, today) ++ CH.list_faq_data(location_ids, today)

    render(conn, "county_show.html", assigns)
  end
end
