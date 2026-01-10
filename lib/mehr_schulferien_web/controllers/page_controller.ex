defmodule MehrSchulferienWeb.PageController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods, Repo}
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferienWeb.Helpers.VacationTypeHelpers
  import Ecto.Query

  def index(conn, %{"number_of_days" => number_of_days}) do
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year
    ends_on = Date.add(today, number_of_days)
    days = DateHelpers.create_days(today, number_of_days)
    day_names = DateHelpers.short_days_map()
    months = DateHelpers.get_months_map()

    # Calculate months_with_days for the timeline
    month_groups =
      days
      |> Enum.group_by(fn day -> {day.year, day.month} end)
      |> Enum.sort()

    months_with_days =
      Enum.map(month_groups, fn {{year, month}, month_days} ->
        month_name = Map.get(months, month, "") |> to_string()
        {month_name, length(month_days), year, month}
      end)

    # Fetch everything in a more efficient way
    countries = fetch_countries_with_periods(today, ends_on, current_year)

    render(conn, "index.html",
      countries: countries,
      days: days,
      day_names: day_names,
      months: months,
      current_year: current_year,
      number_of_days: number_of_days,
      months_with_days: months_with_days
    )
  end

  def index(conn, _params) do
    index(conn, %{"number_of_days" => 80})
  end

  def summer_vacations(conn, _params) do
    render_vacation_type_page(conn, "sommer")
  end

  def easter_vacations(conn, _params) do
    render_vacation_type_page(conn, "ostern")
  end

  def fall_vacations(conn, _params) do
    render_vacation_type_page(conn, "herbst")
  end

  def christmas_vacations(conn, _params) do
    render_vacation_type_page(conn, "weihnachten")
  end

  def winter_vacations(conn, _params) do
    render_vacation_type_page(conn, "winter")
  end

  def pentecost_vacations(conn, _params) do
    render_vacation_type_page(conn, "pfingsten")
  end

  # Generic function to render vacation type pages
  defp render_vacation_type_page(conn, vacation_type) do
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year

    # Fetch data for current and next year
    current_year_data =
      VacationTypeHelpers.fetch_vacation_data_for_type(vacation_type, current_year)

    next_year_data =
      VacationTypeHelpers.fetch_vacation_data_for_type(vacation_type, current_year + 1)

    # Format data for display
    current_year_table = VacationTypeHelpers.format_vacation_table_data(current_year_data)
    next_year_table = VacationTypeHelpers.format_vacation_table_data(next_year_data)

    # Generate structured data (returns list of ItemLists for both years)
    structured_data =
      VacationTypeHelpers.generate_vacation_structured_data(
        vacation_type,
        current_year,
        current_year_data,
        next_year_data,
        conn
      )

    # Get vacation config
    config = VacationTypeHelpers.get_vacation_config(vacation_type)

    render(conn, "vacation_type.html",
      vacation_type: vacation_type,
      vacation_config: config,
      current_year: current_year,
      next_year: current_year + 1,
      current_year_data: current_year_table,
      next_year_data: next_year_table,
      structured_data: structured_data
    )
  end

  def developers(conn, _params) do
    render(conn, "developers.html")
  end

  def developers_api(conn, _params) do
    render(conn, "developers_api_overview.html",
      page_title: "REST API v2.1 Dokumentation - Schulferien & Feiertage API"
    )
  end

  def developers_api_locations(conn, _params) do
    render(conn, "developers_api_locations.html", page_title: "Standorte API - Dokumentation")
  end

  def developers_api_periods(conn, _params) do
    render(conn, "developers_api_periods.html",
      page_title: "Ferien & Feiertage API - Dokumentation"
    )
  end

  def developers_api_bridge_days(conn, _params) do
    render(conn, "developers_api_bridge_days.html", page_title: "Brückentage API - Dokumentation")
  end

  def developers_api_exports(conn, _params) do
    render(conn, "developers_api_exports.html", page_title: "Export-Formate API - Dokumentation")
  end

  def developers_api_pdf(conn, _params) do
    render(conn, "developers_api_pdf.html", page_title: "PDF-Dokumente API - Dokumentation")
  end

  def developers_api_reference(conn, _params) do
    render(conn, "developers_api_reference.html", page_title: "API-Referenz - Dokumentation")
  end

  def developers_api_queries(conn, _params) do
    render(conn, "developers_api_queries.html", page_title: "Datum-Abfragen API - Dokumentation")
  end

  def developers_api_vacation_optimizer(conn, _params) do
    render(conn, "developers_api_vacation_optimizer.html",
      page_title: "Urlaubsplaner API - Dokumentation"
    )
  end

  def developers_mcp(conn, _params) do
    render(conn, "developers_mcp.html")
  end

  def impressum(conn, _params) do
    render(conn, "impressum.html")
  end

  def debug(conn, _params) do
    # Elixir version
    elixir_version = System.version()

    # Erlang/OTP version (major.minor)
    erlang_version =
      :erlang.system_info(:otp_release)
      |> to_string()

    # Get ERTS version for more detail
    erts_version =
      :erlang.system_info(:version)
      |> to_string()

    # Environment
    environment = Application.get_env(:mehr_schulferien, :env) || Mix.env()

    # Database check - count cities and schools
    {cities_count, schools_count, db_status} =
      try do
        cities = Repo.aggregate(from(l in Location, where: l.is_city == true), :count, :id)
        schools = Locations.count_schools()
        {cities, schools, :ok}
      rescue
        e -> {0, 0, {:error, Exception.message(e)}}
      end

    # App version from mix.exs
    app_version = Application.spec(:mehr_schulferien, :vsn) |> to_string()

    # Deployment timestamp - check for priv/static/cache_manifest.json modification time
    # or use application start time as fallback
    deployment_timestamp = get_deployment_timestamp()

    render(conn, "debug.html",
      elixir_version: elixir_version,
      erlang_version: erlang_version,
      erts_version: erts_version,
      environment: environment,
      cities_count: cities_count,
      schools_count: schools_count,
      db_status: db_status,
      app_version: app_version,
      deployment_timestamp: deployment_timestamp
    )
  end

  defp get_deployment_timestamp do
    # Try to get the modification time of priv/static/cache_manifest.json
    # which is generated during asset deployment
    manifest_path = Application.app_dir(:mehr_schulferien, "priv/static/cache_manifest.json")

    case File.stat(manifest_path) do
      {:ok, %{mtime: mtime}} ->
        mtime
        |> NaiveDateTime.from_erl!()
        |> NaiveDateTime.to_string()

      _ ->
        # Fallback: use application start time
        case :application.get_key(:mehr_schulferien, :start_time) do
          {:ok, start_time} -> start_time
          _ -> "Unknown"
        end
    end
  end

  def home(conn, params) do
    # Start performance timing
    start_time = System.monotonic_time(:microsecond)

    # Parse days parameter
    days_to_display = parse_days_count(params["days"])

    # Use our custom date or the current date
    today = DateHelpers.get_today_or_custom_date(conn)

    # We don't need to set noindex here as it's already set by the DateAssignsPlug
    # when a custom date is present

    # Use the actual start date for year calculation
    current_year = today.year
    number_of_days = days_to_display
    ends_on = Date.add(today, number_of_days)

    # Generate calendar data
    days = DateHelpers.create_days(today, number_of_days)
    day_names = DateHelpers.short_days_map()
    months = DateHelpers.get_months_map()
    months_with_days = calculate_months_with_days(days, months)

    # Fetch countries data - with performance tracking
    {countries, query_time} =
      measure_time(fn ->
        fetch_countries_with_periods_optimized(today, ends_on, current_year)
      end)

    # End performance timing
    end_time = System.monotonic_time(:microsecond)
    # Convert to milliseconds
    total_time = (end_time - start_time) / 1000

    # Log performance
    require Logger

    Logger.info(
      "Home page performance: Total #{Float.round(total_time, 2)}ms, Queries #{Float.round(query_time, 2)}ms"
    )

    render(conn, "home.html",
      countries: countries,
      days: days,
      day_names: day_names,
      months: months,
      current_year: current_year,
      number_of_days: number_of_days,
      custom_start_date: conn.assigns.custom_date,
      days_to_display: days_to_display,
      months_with_days: months_with_days,
      elapsed_time: Float.round(total_time, 2)
    )
  end

  # Parses and validates the days count
  defp parse_days_count(nil), do: 80

  defp parse_days_count(days_str) do
    case Integer.parse(days_str) do
      {days, _} when days > 0 and days <= 365 -> days
      _ -> 80
    end
  end

  # Calculates the months with days for the timeline
  defp calculate_months_with_days(days, months) do
    days
    |> Enum.group_by(fn day -> {day.year, day.month} end)
    |> Enum.sort()
    |> Enum.map(fn {{year, month}, month_days} ->
      month_name = Map.get(months, month, "") |> to_string()
      {month_name, length(month_days), year, month}
    end)
  end

  # Helper to measure execution time
  defp measure_time(fun) do
    start = System.monotonic_time(:microsecond)
    result = fun.()
    finish = System.monotonic_time(:microsecond)
    # Return result and time in ms
    {result, (finish - start) / 1000}
  end

  # Optimized version that reduces SQL queries with ETS caching
  defp fetch_countries_with_periods_optimized(start_date, ends_on, current_year) do
    # Cached query to get countries with federal states (selective columns for 56% faster performance)
    countries_with_federal_states = Locations.list_countries_with_federal_states_cached()

    # Extract all location IDs for batch queries
    all_location_ids =
      Enum.flat_map(countries_with_federal_states, fn {country, federal_states} ->
        [country.id | Enum.map(federal_states, & &1.id)]
      end)

    # Cached query for all periods
    all_periods =
      Periods.list_school_free_periods_cached(all_location_ids, start_date, ends_on)

    # Group periods by location_id for O(1) lookup
    periods_by_location =
      all_periods
      |> Enum.group_by(& &1.location_id)
      |> Map.new()

    # Years to check for bridge days
    years = [current_year, current_year + 1, current_year + 2]

    # Get bridge days info for all states and years in a single query
    bridge_days_info = fetch_all_bridge_days_info(countries_with_federal_states, years)

    # Build the final data structure
    Enum.map(countries_with_federal_states, fn {country, federal_states} ->
      # Get country periods
      country_periods = Map.get(periods_by_location, country.id, [])

      # Process federal states with bridge day info
      federal_states_with_bridge_days =
        Enum.map(federal_states, fn state ->
          # Get years that have bridge days from the precomputed result
          years_with_bridge_days =
            years
            |> Enum.filter(fn year ->
              Map.get(bridge_days_info, {state.id, year}, false)
            end)

          Map.put(state, :years_with_bridge_days, years_with_bridge_days)
        end)

      # Create periods entries for each federal state
      periods =
        Enum.map(federal_states_with_bridge_days, fn state ->
          state_periods = Map.get(periods_by_location, state.id, [])
          {state, country_periods ++ state_periods}
        end)

      # Return the final country entry
      %{
        country: country,
        federal_states: federal_states_with_bridge_days,
        periods: periods
      }
    end)
  end

  # Fetch all bridge days info in a single optimized operation
  defp fetch_all_bridge_days_info(countries_with_federal_states, years) do
    # Get all unique state IDs and country IDs
    {country_ids, state_ids} =
      Enum.reduce(countries_with_federal_states, {[], []}, fn {country, states}, {c_acc, s_acc} ->
        state_ids = Enum.map(states, & &1.id)
        {[country.id | c_acc], state_ids ++ s_acc}
      end)

    country_ids = Enum.uniq(country_ids)
    state_ids = Enum.uniq(state_ids)

    # Get min and max year for date range
    current_year = Date.utc_today().year
    min_year = Enum.min(years, fn -> current_year end)
    max_year = Enum.max(years, fn -> current_year end)
    {:ok, start_date} = Date.new(min_year, 1, 1)
    {:ok, end_date} = Date.new(max_year, 12, 31)

    # Fetch all periods for all locations and years at once
    all_location_ids = country_ids ++ state_ids
    all_periods = Periods.list_public_everybody_periods(all_location_ids, start_date, end_date)

    # Process each state/year combination
    results =
      for state_id <- state_ids, year <- years do
        # Find country for this state
        country_id =
          Enum.find_value(countries_with_federal_states, fn {country, states} ->
            if Enum.any?(states, &(&1.id == state_id)), do: country.id
          end)

        # Filter periods for this year and locations
        {:ok, year_start} = Date.new(year, 1, 1)
        {:ok, year_end} = Date.new(year, 12, 31)

        location_ids = [country_id, state_id]

        year_periods =
          Enum.filter(all_periods, fn period ->
            period.location_id in location_ids and
              Date.compare(period.starts_on, year_end) != :gt and
              Date.compare(period.ends_on, year_start) != :lt
          end)

        # Check if there are bridge days (simplified check)
        has_bridge_days = length(year_periods) >= 2

        {{state_id, year}, has_bridge_days}
      end

    Map.new(results)
  end

  # Legacy function kept for compatibility
  defp fetch_countries_with_periods(start_date, ends_on, current_year) do
    fetch_countries_with_periods_optimized(start_date, ends_on, current_year)
  end
end
