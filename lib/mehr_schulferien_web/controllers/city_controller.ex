defmodule MehrSchulferienWeb.CityController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.ViewHelpers
  alias MehrSchulferienWeb.Helpers.UserAgentHelpers
  import MehrSchulferienWeb.LocationTrackingHelpers

  def show_year(conn, %{
        "country_slug" => country_slug,
        "city_slug" => city_slug,
        "year" => _year
      }) do
    case Locations.show_city_to_country_map_safe(country_slug, city_slug) do
      {:ok, %{country: country}} ->
        # Redirect to the city page without year (301 permanent redirect for SEO)
        conn
        |> put_status(:moved_permanently)
        |> redirect(to: ~p"/ferien/#{country.slug}/stadt/#{city_slug}")

      {:error, _} ->
        conn
        |> put_status(:service_unavailable)
        |> put_view(MehrSchulferienWeb.ErrorView)
        |> render("empty_database.html")
    end
  end

  def show(conn, %{"country_slug" => country_slug, "city_slug" => city_slug}) do
    case Locations.show_city_to_country_map_safe(country_slug, city_slug) do
      {:ok, %{country: country, federal_state: federal_state, county: county, city: city}} ->
        show_city_page(conn, country, federal_state, county, city)

      {:error, _} ->
        conn
        |> put_status(:service_unavailable)
        |> put_view(MehrSchulferienWeb.ErrorView)
        |> render("empty_database.html")
    end
  end

  defp show_city_page(conn, country, federal_state, county, city) do
    # Get schools in this city for display, filtered by zip code prefix
    schools = Locations.list_schools_by_zip_prefix(city)

    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year

    # Determine current school year (starts in August)
    current_school_year = if today.month >= 8, do: current_year, else: current_year - 1
    next_school_year = current_school_year + 1

    location_ids = [country.id, federal_state.id, county.id, city.id]

    # Get all periods for current calendar year and next year
    {:ok, full_start} = Date.new(current_year, 1, 1)
    {:ok, full_end} = Date.new(current_year + 1, 12, 31)

    # Calculate cutoff date (August 2 of next year)
    {:ok, cutoff_date} = Date.new(current_year + 1, 8, 2)

    # Use SQL filter for cutoff_date instead of Elixir filter
    all_periods =
      MehrSchulferien.Periods.list_school_vacation_periods(
        location_ids,
        full_start,
        full_end,
        starts_on_cutoff: cutoff_date
      )

    all_public_periods =
      MehrSchulferien.Periods.list_public_periods(location_ids, full_start, full_end)

    # Check if we have data
    has_data = length(all_periods) > 0

    # Get years with data for navigation - optimized to avoid creating intermediate list
    years_with_data =
      all_periods
      |> Enum.map(& &1.starts_on.year)
      |> Enum.uniq()
      |> Enum.sort()

    # Build period date set ONCE for O(1) lookups (instead of O(n) per period)
    combined_periods = all_periods ++ all_public_periods
    period_date_set = ViewHelpers.build_period_date_set(combined_periods)

    # Calculate adjoining_duration for each period using optimized O(1) lookups
    periods_with_duration =
      Enum.map(all_periods, fn period ->
        days = Date.diff(period.ends_on, period.starts_on) + 1

        effective_duration =
          ViewHelpers.calculate_effective_duration(period, period_date_set, :optimized)

        difference = effective_duration - days
        Map.put(period, :adjoining_duration, difference)
      end)

    # Set the appropriate status code based on data availability
    conn = if has_data, do: conn, else: put_status(conn, 404)

    # Track city visit
    conn = track_location_visit(conn, "c", city.slug)

    # Get FAQ data
    faq_data = CH.list_faq_data(location_ids, today)

    # Detect if user is on Apple device
    is_apple_device = UserAgentHelpers.is_apple_device?(conn)

    render(
      conn,
      "show.html",
      %{
        country: country,
        federal_state: federal_state,
        county: county,
        city: city,
        schools: schools,
        css_framework: :tailwind_new,
        periods: periods_with_duration,
        public_periods: all_public_periods,
        all_periods: all_periods ++ all_public_periods,
        current_year: current_year,
        next_year: current_year + 1,
        current_school_year: current_school_year,
        next_school_year: next_school_year,
        years_with_data: years_with_data,
        today: today,
        has_data: has_data,
        is_apple_device: is_apple_device
      }
      |> Map.merge(Map.new(faq_data))
    )
  end
end
