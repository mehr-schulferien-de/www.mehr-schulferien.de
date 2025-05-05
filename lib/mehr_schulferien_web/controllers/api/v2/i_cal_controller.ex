defmodule MehrSchulferienWeb.Api.V2.ICalController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Locations, Periods}

  def show(conn, %{"slug" => slug, "vacation_types" => vacation_types, "year" => year}) do
    location = Locations.get_location_by_slug!(slug)
    location_ids = Locations.recursive_location_ids(location)
    year = String.to_integer(year)
    {:ok, start_date} = Date.new(year, 8, 1)
    {:ok, end_date} = Date.new(year + 1, 7, 31)
    periods = list_periods(vacation_types, location_ids, start_date, end_date)

    conn
    |> update_headers(location.name, year)
    |> render("icalendar.ics", location: location, periods: periods)
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

  defp update_headers(conn, name, year) do
    filename = "#{String.replace(name, [" ", "-"], "_")}_#{year}-#{year + 1}_icalendar.ics"

    conn
    |> put_resp_header("content-type", "text/calendar; charset=utf-8")
    |> put_resp_header("content-disposition", "attachment; filename=#{filename}")
  end
end
