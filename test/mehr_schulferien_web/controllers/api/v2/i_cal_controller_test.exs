defmodule MehrSchulferienWeb.Api.V2.ICalControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Periods

  setup %{conn: conn} do
    location = insert(:federal_state)
    year = Date.utc_today().year
    {:ok, start_date} = Date.new(year, 8, 1)
    {:ok, end_date} = Date.new(year + 1, 7, 31)
    school_periods = add_school_periods(%{location: location})

    public_periods =
      insert_list(3, :period, %{
        is_public_holiday: true,
        location_id: location.id,
        starts_on: start_date,
        ends_on: end_date
      })

    {:ok,
     %{
       conn: conn,
       location: location,
       public_periods: public_periods,
       school_periods: school_periods,
       year: year
     }}
  end

  test "shows icalendar for school vacations for location", %{
    conn: conn,
    location: location,
    public_periods: public_periods,
    school_periods: school_periods,
    year: year
  } do
    conn =
      get(
        conn,
        Routes.api_i_cal_path(conn, :show, location.slug, vacation_types: "school", year: year)
      )

    assert conn.status == 200
    icalendar = conn.resp_body
    assert icalendar =~ "BEGIN:VCALENDAR\nCALSCALE:GREGORIAN"
    school_period = get_random_period(school_periods, year)
    assert icalendar =~ "DESCRIPTION:#{school_period.holiday_or_vacation_type.name}"
    assert icalendar =~ "DTSTART:#{Date.to_iso8601(school_period.starts_on, :basic)}"
    public_period = get_random_period(public_periods, year)
    refute icalendar =~ "DTSTART:#{Date.to_iso8601(public_period.starts_on, :basic)}"
  end

  test "shows icalendar for all holidays for location", %{
    conn: conn,
    location: location,
    public_periods: public_periods,
    school_periods: school_periods,
    year: year
  } do
    conn =
      get(
        conn,
        Routes.api_i_cal_path(conn, :show, location.slug, vacation_types: "all", year: year)
      )

    assert conn.status == 200
    icalendar = conn.resp_body
    assert icalendar =~ "BEGIN:VCALENDAR\nCALSCALE:GREGORIAN"
    school_period = get_random_period(school_periods, year)
    assert icalendar =~ "DESCRIPTION:#{school_period.holiday_or_vacation_type.name}"
    assert icalendar =~ "DTSTART:#{Date.to_iso8601(school_period.starts_on, :basic)}"
    public_period = get_random_period(public_periods, year)
    assert icalendar =~ "DTSTART:#{Date.to_iso8601(public_period.starts_on, :basic)}"
  end

  defp get_random_period(periods, year) do
    {:ok, start_date} = Date.new(year, 8, 1)
    {:ok, end_date} = Date.new(year + 1, 7, 31)

    period =
      periods
      |> Enum.filter(
        &(Date.compare(&1.starts_on, start_date) != :lt and
            Date.compare(&1.starts_on, end_date) != :gt)
      )
      |> Enum.random()

    Periods.get_period!(period.id)
  end
end
