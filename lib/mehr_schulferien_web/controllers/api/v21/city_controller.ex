defmodule MehrSchulferienWeb.Api.V21.CityController do
  @moduledoc """
  API v2.1 controller for cities.

  Provides endpoints for:
  - Listing all cities
  - Getting a specific city by slug
  - Getting periods for a city
  - Generating iCalendar for a city
  """
  use MehrSchulferienWeb.Api.V21.BaseController

  alias MehrSchulferien.Periods.CustomICal

  def index(conn, params) do
    cities =
      build_index_query(params)
      |> Repo.all()
      |> Enum.map(&format_location/1)

    render_json(conn, cities)
  end

  def show(conn, %{"slug" => slug}) do
    with {:ok, city} <- get_city_by_slug(slug) do
      render_json(conn, format_location(city))
    end
  end

  def periods(conn, %{"slug" => slug} = params) do
    with {:ok, city} <- get_city_by_slug(slug) do
      {start_date, end_date} = parse_date_range(params)
      location_ids = Locations.recursive_location_ids(city)

      periods =
        case params["type"] do
          "vacation" ->
            Periods.list_school_vacation_periods(location_ids, start_date, end_date)

          "holiday" ->
            Periods.list_public_periods(location_ids, start_date, end_date)

          _ ->
            Periods.list_school_vacation_periods(location_ids, start_date, end_date) ++
              Periods.list_public_periods(location_ids, start_date, end_date)
        end
        |> Enum.map(&format_period/1)
        |> Enum.sort_by(& &1.starts_on)

      render_json(conn, periods, %{
        location: format_location(city),
        date_range: %{
          start_date: start_date,
          end_date: end_date
        }
      })
    end
  end

  def icalendar(conn, %{"slug" => slug} = params) do
    with {:ok, city} <- get_city_by_slug(slug) do
      ical_params = parse_ical_params(params)
      location_ids = Locations.recursive_location_ids(city)

      {start_date, end_date, is_school_year} =
        get_date_range(ical_params.year, ical_params.use_calendar_year)

      periods = list_periods(ical_params.vacation_types, location_ids, start_date, end_date)

      # For calendar year view, filter periods to only include days within the specified year
      periods =
        if ical_params.use_calendar_year do
          filter_periods_by_calendar_year(periods, ical_params.year)
        else
          periods
        end

      ical_content = CustomICal.generate(periods, city)

      conn
      |> put_resp_header("content-type", "text/calendar; charset=utf-8")
      |> put_resp_header(
        "content-disposition",
        build_ical_filename(city.name, ical_params.year, is_school_year)
      )
      |> text(ical_content)
    end
  end

  # Private functions

  defp build_index_query(params) do
    query =
      from l in Location,
        where: l.is_city == true,
        order_by: [asc: l.name]

    query =
      case params["federal_state"] do
        nil ->
          query

        federal_state_slug ->
          from l in query,
            join: fs in Location,
            on: l.parent_location_id == fs.id,
            where: fs.slug == ^federal_state_slug and fs.is_federal_state == true
      end

    case params["county"] do
      nil ->
        query

      county_slug ->
        from l in query,
          join: c in Location,
          on: l.parent_location_id == c.id,
          where: c.slug == ^county_slug and c.is_county == true
    end
  end

  defp get_city_by_slug(slug) do
    query =
      from l in Location,
        where: l.slug == ^slug and l.is_city == true

    case Repo.one(query) do
      nil -> {:error, :not_found}
      city -> {:ok, city}
    end
  end

  defp list_periods("all", location_ids, start_date, end_date) do
    periods =
      list_school_vacation_periods(location_ids, start_date, end_date) ++
        Periods.list_public_periods(location_ids, start_date, end_date)

    Enum.sort(periods, &(Date.compare(&1.starts_on, &2.starts_on) != :gt))
  end

  defp list_periods(_, location_ids, start_date, end_date) do
    list_school_vacation_periods(location_ids, start_date, end_date)
  end

  defp list_school_vacation_periods(location_ids, start_date, end_date) do
    location_ids
    |> Periods.list_school_vacation_periods(start_date, end_date)
    |> Enum.reject(
      &(&1.holiday_or_vacation_type.name == "Sommer" and
          Date.compare(&1.starts_on, start_date) == :lt)
    )
  end

  defp filter_periods_by_calendar_year(periods, year) do
    {:ok, year_start} = Date.new(year, 1, 1)
    {:ok, year_end} = Date.new(year, 12, 31)

    Enum.map(periods, fn period ->
      cond do
        # Period starts before this year and ends after this year
        Date.compare(period.starts_on, year_start) == :lt &&
            Date.compare(period.ends_on, year_end) == :gt ->
          %{period | starts_on: year_start, ends_on: year_end}

        # Period starts before this year and ends within this year
        Date.compare(period.starts_on, year_start) == :lt &&
            Date.compare(period.ends_on, year_start) != :lt ->
          %{period | starts_on: year_start}

        # Period starts within this year and ends after this year
        Date.compare(period.starts_on, year_end) != :gt &&
            Date.compare(period.ends_on, year_end) == :gt ->
          %{period | ends_on: year_end}

        # Period is entirely within this year
        true ->
          period
      end
    end)
  end

  defp build_ical_filename(name, year, true = _is_school_year) do
    sanitized_name = String.replace(name, [" ", "-"], "_")
    "attachment; filename=Schulferien_#{sanitized_name}_Schuljahr_#{year}-#{year + 1}.ics"
  end

  defp build_ical_filename(name, year, false = _is_school_year) do
    sanitized_name = String.replace(name, [" ", "-"], "_")
    "attachment; filename=Schulferien_#{sanitized_name}_#{year}.ics"
  end
end
