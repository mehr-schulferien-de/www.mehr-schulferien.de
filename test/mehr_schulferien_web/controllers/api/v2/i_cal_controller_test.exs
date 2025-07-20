defmodule MehrSchulferienWeb.Api.V2.ICalControllerTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory

  setup %{conn: conn} do
    location = insert(:federal_state)
    holiday_type = insert(:holiday_or_vacation_type, %{name: "Test Holiday"})

    # Create periods with unique date ranges
    periods =
      add_test_periods(%{
        location: location,
        start_date: ~D[2025-01-01],
        end_date: ~D[2025-12-31],
        holiday_type: holiday_type
      })

    {:ok, %{conn: conn, location: location, periods: periods, holiday_type: holiday_type}}
  end

  defp add_test_periods(%{location: location, start_date: start_date, holiday_type: holiday_type}) do
    # Create three periods with different date ranges
    [
      %{
        starts_on: start_date,
        ends_on: Date.add(start_date, 5),
        location_id: location.id,
        holiday_or_vacation_type_id: holiday_type.id,
        created_by_email_address: "test@example.com",
        is_school_vacation: true
      },
      %{
        # Start a month later
        starts_on: Date.add(start_date, 30),
        ends_on: Date.add(start_date, 35),
        location_id: location.id,
        holiday_or_vacation_type_id: holiday_type.id,
        created_by_email_address: "test@example.com",
        is_school_vacation: true
      },
      %{
        # Start two months later
        starts_on: Date.add(start_date, 60),
        ends_on: Date.add(start_date, 65),
        location_id: location.id,
        holiday_or_vacation_type_id: holiday_type.id,
        created_by_email_address: "test@example.com",
        is_school_vacation: true
      }
    ]
    |> Enum.map(&MehrSchulferien.Periods.create_period/1)
    |> Enum.map(fn {:ok, period} -> period end)
  end

  test "shows icalendar for school vacations for location", %{conn: conn, location: location} do
    conn =
      get(
        conn,
        ~p"/api/v2.0/icalendars/location/#{location.slug}?vacation_types=school&year=2025"
      )

    assert response_content_type(conn, :ics)
  end

  test "shows icalendar for all holidays for location", %{conn: conn, location: location} do
    conn =
      get(
        conn,
        ~p"/api/v2.0/icalendars/location/#{location.slug}?vacation_types=all&year=2025"
      )

    assert response_content_type(conn, :ics)
  end

  test "uses calendar year when calendar_year parameter is true", %{
    conn: conn,
    location: location
  } do
    path =
      ~p"/api/v2.0/icalendars/location/#{location.slug}?vacation_types=school&year=2025&calendar_year=true"

    conn = get(conn, path)

    # Get result body and check for January 1 date which confirms calendar year
    response = response(conn, 200)
    assert String.contains?(response, "20250101")

    # Verify filename in content disposition header shows just the year (not year-year+1)
    content_disposition =
      Enum.find_value(conn.resp_headers, fn {header, value} ->
        if header == "content-disposition", do: value, else: nil
      end)

    assert content_disposition =~ "_2025.ics"
    assert response_content_type(conn, :ics)
  end

  test "uses school year when calendar_year parameter is not set", %{
    conn: conn,
    location: location
  } do
    # Without calendar_year parameter, it should use school year format
    path = ~p"/api/v2.0/icalendars/location/#{location.slug}?vacation_types=school&year=2025"

    conn = get(conn, path)

    # Verify filename in content disposition header shows the school year format (year-year+1)
    content_disposition =
      Enum.find_value(conn.resp_headers, fn {header, value} ->
        if header == "content-disposition", do: value, else: nil
      end)

    assert content_disposition =~ "Schuljahr_2025-2026.ics"
    assert response_content_type(conn, :ics)
  end

  test "prefers federal state when multiple locations have same slug", %{
    conn: conn
  } do
    # Create a federal state with slug "hessen"
    federal_state = insert(:federal_state, %{name: "Hessen", slug: "hessen"})

    # Create a city with the same slug "hessen"
    city = insert(:city, %{name: "Hessen", slug: "hessen"})

    # Add periods for the federal state (in school year 2021/2022)
    insert(:period, %{
      location_id: federal_state.id,
      starts_on: ~D[2021-10-11],
      ends_on: ~D[2021-10-23],
      is_school_vacation: true,
      is_valid_for_students: true
    })

    # Add periods for the city (should not be included in result)
    insert(:period, %{
      location_id: city.id,
      starts_on: ~D[2021-12-23],
      ends_on: ~D[2022-01-08],
      is_school_vacation: true,
      is_valid_for_students: true
    })

    # Request iCal for "hessen" - should get federal state data
    conn =
      get(
        conn,
        ~p"/api/v2.0/icalendars/location/hessen?vacation_types=school&year=2021"
      )

    assert response_content_type(conn, :ics)
    response = response(conn, 200)

    # Should contain the federal state's vacation period
    assert String.contains?(response, "DTSTART;VALUE=DATE:20211011")
    # iCal uses exclusive end date
    assert String.contains?(response, "DTEND;VALUE=DATE:20211024")
    assert String.contains?(response, "Hessen")

    # Should NOT contain the city's vacation period dates
    refute String.contains?(response, "20211223")
    # Would be 20220109 as exclusive end date
    refute String.contains?(response, "20220109")

    # Verify the filename uses the federal state name
    content_disposition =
      Enum.find_value(conn.resp_headers, fn {header, value} ->
        if header == "content-disposition", do: value, else: nil
      end)

    assert content_disposition =~ "Schulferien_Hessen_Schuljahr_2021-2022.ics"
  end
end
