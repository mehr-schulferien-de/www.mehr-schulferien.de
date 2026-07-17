defmodule MehrSchulferienWeb.FederalStateController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods}
  alias MehrSchulferien.Calendars.VacationTypes
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.ViewHelpers
  import MehrSchulferienWeb.LocationTrackingHelpers

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

    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/ferien/#{country_slug}/bundesland/#{location.slug}")
  end

  def show(conn, %{"country_slug" => country_slug, "federal_state_slug" => federal_state_slug}) do
    case Locations.get_federal_state_and_country_by_slug(country_slug, federal_state_slug) do
      {:ok, {federal_state, country}} ->
        show_evergreen(conn, federal_state, country)

      {:error, :not_found} ->
        CH.render_not_found_or_empty_database(conn)
    end
  end

  # Evergreen page for the head term "Schulferien <Bundesland>": one stable URL
  # per state showing the current and next school year, mirroring the year-less
  # city pages that rank well.
  defp show_evergreen(conn, federal_state, country) do
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year
    next_year = current_year + 1
    location_ids = [country.id, federal_state.id]

    {:ok, full_start} = Date.new(current_year, 1, 1)
    {:ok, full_end} = Date.new(next_year, 12, 31)
    {:ok, cutoff_date} = Date.new(next_year, 8, 2)

    school_periods =
      Periods.list_school_vacation_periods(location_ids, full_start, full_end,
        starts_on_cutoff: cutoff_date
      )

    public_periods = Periods.list_public_periods(location_ids, full_start, full_end)

    has_data = school_periods != []
    conn = if has_data, do: conn, else: put_status(conn, 404)
    conn = track_location_visit(conn, "f", federal_state.slug)

    years_with_data =
      school_periods |> Enum.map(& &1.starts_on.year) |> Enum.uniq() |> Enum.sort()

    all_periods = school_periods ++ public_periods

    periods_with_duration =
      ViewHelpers.add_adjoining_duration_to_periods(school_periods, all_periods)

    vacation_types = VacationTypes.list_for_year(federal_state, current_year)
    faq_data = CH.list_faq_data(location_ids, today)

    render(
      conn,
      "show.html",
      %{
        country: country,
        federal_state: federal_state,
        periods: periods_with_duration,
        public_periods: public_periods,
        all_periods: all_periods,
        current_year: current_year,
        next_year: next_year,
        years_with_data: years_with_data,
        today: today,
        has_data: has_data,
        vacation_types: vacation_types
      }
      |> Map.merge(Map.new(faq_data))
    )
  end

  def show_year(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    # Try to get the federal state and country, handle empty database case
    case Locations.get_federal_state_and_country_by_slug(country_slug, federal_state_slug) do
      {:ok, {federal_state, country}} ->
        # Check if year is "brueckentage" and handle special case
        if year == "brueckentage" do
          conn = Plug.Conn.put_status(conn, :not_found)
          raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router
        end

        show_year_with_data(conn, federal_state, country, year)

      {:error, :not_found} ->
        CH.render_not_found_or_empty_database(conn)
    end
  end

  defp show_year_with_data(conn, federal_state, country, year) do
    today = DateHelpers.get_today_or_custom_date(conn)
    location_ids = [country.id, federal_state.id]

    # Use shared logic to prepare show_year data
    data = CH.prepare_show_year_data(location_ids, year, today)

    # Calculate adjoining_duration for each period
    periods_with_duration =
      ViewHelpers.add_adjoining_duration_to_periods(data.periods, data.all_periods)

    # Set the appropriate status code based on data availability
    conn = if data.has_data, do: conn, else: put_status(conn, 404)

    # Track federal state visit
    conn = track_location_visit(conn, "f", federal_state.slug)

    # Get vacation types for this federal state and specific year
    vacation_types = VacationTypes.list_for_year(federal_state, year)

    render(
      conn,
      "show_year.html",
      %{
        country: country,
        federal_state: federal_state,
        periods: periods_with_duration,
        all_periods: data.all_periods,
        vacation_types: vacation_types
      }
      |> Map.merge(data)
      |> Map.merge(Map.new(data.faq_data))
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
        federal_state: federal_state
      ] ++
        CH.list_period_data(location_ids, today) ++ CH.list_faq_data(location_ids, today)

    render(conn, "county_show.html", assigns)
  rescue
    Ecto.NoResultsError ->
      CH.render_not_found_or_empty_database(conn)
  end
end
