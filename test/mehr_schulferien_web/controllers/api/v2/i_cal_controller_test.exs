defmodule MehrSchulferienWeb.Api.V2.ICalControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Periods

  setup %{conn: conn} do
    location = insert(:federal_state)
    school_periods = add_school_periods(%{location: location})
    public_periods = add_public_periods(%{location: location})

    {:ok,
     %{
       conn: conn,
       location: location,
       public_periods: public_periods,
       school_periods: school_periods
     }}
  end

  test "shows icalendar for school vacations for location", %{
    conn: conn,
    location: location,
    public_periods: public_periods,
    school_periods: school_periods
  } do
    conn = get(conn, Routes.api_i_cal_path(conn, :show, location.slug, vacation_types: "school"))
    assert conn.status == 200
    icalendar = conn.resp_body
    assert icalendar =~ "BEGIN:VCALENDAR\nCALSCALE:GREGORIAN"
    school_period = get_random_period(school_periods)
    assert icalendar =~ "DESCRIPTION:#{school_period.holiday_or_vacation_type.name}"
    assert icalendar =~ "DTSTART:#{Date.to_iso8601(school_period.starts_on, :basic)}"
    public_period = get_random_period(public_periods)
    refute icalendar =~ "DTSTART:#{Date.to_iso8601(public_period.starts_on, :basic)}"
  end

  test "shows icalendar for all holidays for location", %{
    conn: conn,
    location: location,
    public_periods: public_periods,
    school_periods: school_periods
  } do
    conn = get(conn, Routes.api_i_cal_path(conn, :show, location.slug, vacation_types: "all"))
    assert conn.status == 200
    icalendar = conn.resp_body
    assert icalendar =~ "BEGIN:VCALENDAR\nCALSCALE:GREGORIAN"
    school_period = get_random_period(school_periods)
    assert icalendar =~ "DESCRIPTION:#{school_period.holiday_or_vacation_type.name}"
    assert icalendar =~ "DTSTART:#{Date.to_iso8601(school_period.starts_on, :basic)}"
    public_period = get_random_period(public_periods)
    assert icalendar =~ "DTSTART:#{Date.to_iso8601(public_period.starts_on, :basic)}"
  end

  defp get_random_period(periods) do
    period = Enum.random(periods)
    Periods.get_period!(period.id)
  end
end
