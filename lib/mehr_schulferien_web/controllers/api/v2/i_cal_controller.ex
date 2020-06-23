defmodule MehrSchulferienWeb.Api.V2.ICalController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods}

  def show(conn, %{"slug" => slug, "vacation_types" => vacation_types}) do
    location = Locations.get_location_by_slug!(slug)
    location_ids = Locations.recursive_location_ids(location)
    current_year = DateHelpers.today_berlin().year
    {:ok, start_date} = Date.new(current_year, 1, 1)
    {:ok, end_date} = Date.new(current_year + 2, 12, 31)
    periods = list_periods(vacation_types, location_ids, start_date, end_date)

    conn
    |> update_headers(slug)
    |> render("icalendar.ics", location: location, periods: periods)
  end

  defp list_periods("all", location_ids, start_date, end_date) do
    Periods.list_school_periods(location_ids, start_date, end_date) ++
      Periods.list_public_periods(location_ids, start_date, end_date)
  end

  defp list_periods(_, location_ids, start_date, end_date) do
    Periods.list_school_periods(location_ids, start_date, end_date)
  end

  defp update_headers(conn, slug) do
    filename = "#{String.replace(slug, ".", "_")}_icalendar.ics"

    conn
    |> put_resp_header("content-type", "text/calendar; charset=utf-8")
    |> put_resp_header("content-disposition", "attachment; filename=#{filename}")
  end
end
