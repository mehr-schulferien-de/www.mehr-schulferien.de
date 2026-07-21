defmodule MehrSchulferienWeb.PageController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Repo}
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferienWeb.Helpers.VacationTypeHelpers
  import Ecto.Query

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
      vacation_url_slug: MehrSchulferien.Calendars.VacationSlug.url_slug(vacation_type),
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
    render(conn, "developers_mcp.html",
      page_title: "MCP Server Dokumentation - Schulferien & Feiertage für KI-Assistenten"
    )
  end

  def impressum(conn, _params) do
    render(conn, "impressum.html",
      page_title: "Impressum und Datenschutzerklärung - mehr-schulferien.de"
    )
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
    {deployment_timestamp, deployment_relative} = get_deployment_timestamp()

    render(conn, "debug.html",
      elixir_version: elixir_version,
      erlang_version: erlang_version,
      erts_version: erts_version,
      environment: environment,
      cities_count: cities_count,
      schools_count: schools_count,
      db_status: db_status,
      app_version: app_version,
      deployment_timestamp: deployment_timestamp,
      deployment_relative: deployment_relative
    )
  end

  defp get_deployment_timestamp do
    # Try to get the modification time of priv/static/cache_manifest.json
    # which is generated during asset deployment
    manifest_path = Application.app_dir(:mehr_schulferien, "priv/static/cache_manifest.json")

    case File.stat(manifest_path) do
      {:ok, %{mtime: mtime}} ->
        datetime =
          mtime
          |> NaiveDateTime.from_erl!()
          |> DateTime.from_naive!("Etc/UTC")
          |> DateTime.shift_zone!("Europe/Berlin")

        {format_german_datetime(datetime), relative_time_ago(datetime)}

      _ ->
        # Fallback: use application start time
        case :application.get_key(:mehr_schulferien, :start_time) do
          {:ok, start_time} -> {start_time, ""}
          _ -> {"Unknown", ""}
        end
    end
  end

  defp relative_time_ago(datetime) do
    now = DateTime.now!("Europe/Berlin")
    diff_seconds = DateTime.diff(now, datetime, :second)

    cond do
      diff_seconds < 60 ->
        "just now"

      diff_seconds < 3600 ->
        minutes = div(diff_seconds, 60)
        if minutes == 1, do: "1 minute ago", else: "#{minutes} minutes ago"

      diff_seconds < 86_400 ->
        hours = div(diff_seconds, 3600)
        if hours == 1, do: "1 hour ago", else: "#{hours} hours ago"

      true ->
        days = div(diff_seconds, 86_400)
        if days == 1, do: "1 day ago", else: "#{days} days ago"
    end
  end

  defp format_german_datetime(datetime) do
    day = String.pad_leading("#{datetime.day}", 2, "0")
    month = String.pad_leading("#{datetime.month}", 2, "0")
    year = datetime.year
    hour = String.pad_leading("#{datetime.hour}", 2, "0")
    minute = String.pad_leading("#{datetime.minute}", 2, "0")
    second = String.pad_leading("#{datetime.second}", 2, "0")

    "#{day}.#{month}.#{year} #{hour}:#{minute}:#{second}"
  end
end
