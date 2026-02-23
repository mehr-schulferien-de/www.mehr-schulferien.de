defmodule MehrSchulferienWeb.Api.V21.VacationOptimizerControllerTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  setup %{conn: conn} do
    # Create a country
    country = get_or_create_deutschland()

    # Create federal state
    bayern =
      insert(:federal_state, %{
        name: "Bayern",
        slug: "bayern",
        code: "BY",
        parent_location_id: country.id
      })

    # Create public holiday type
    holiday_type =
      insert(:holiday_or_vacation_type, %{
        name: "Tag der Arbeit",
        slug: "tag-der-arbeit",
        default_is_public_holiday: true,
        default_is_school_vacation: false,
        country_location_id: country.id
      })

    # Create holidays
    year = Date.utc_today().year

    # Create a holiday on May 1st
    insert(:period, %{
      location_id: country.id,
      starts_on: Date.new!(year, 5, 1),
      ends_on: Date.new!(year, 5, 1),
      holiday_or_vacation_type_id: holiday_type.id,
      is_school_vacation: false,
      is_public_holiday: true,
      is_valid_for_everybody: true,
      created_by_email_address: "test@example.com"
    })

    # Create school vacation type for budget variant tests
    school_vacation_type =
      insert(:holiday_or_vacation_type, %{
        name: "Osterferien",
        slug: "osterferien",
        default_is_school_vacation: true,
        default_is_valid_for_students: true,
        country_location_id: country.id
      })

    # Create school vacation period
    insert(:period, %{
      location_id: bayern.id,
      starts_on: Date.new!(year, 4, 14),
      ends_on: Date.new!(year, 4, 25),
      holiday_or_vacation_type_id: school_vacation_type.id,
      is_school_vacation: true,
      is_valid_for_students: true,
      created_by_email_address: "test@example.com"
    })

    {:ok,
     conn: put_req_header(conn, "accept", "application/json"),
     country: country,
     bayern: bayern,
     year: year}
  end

  describe "GET /api/v2.1/federal-states/:slug/vacation-optimizer" do
    test "returns optimal vacation windows for valid parameters", %{
      conn: conn,
      bayern: bayern,
      year: year
    } do
      conn =
        get(
          conn,
          "/api/v2.1/federal-states/#{bayern.slug}/vacation-optimizer?year=#{year}&days=5"
        )

      response = json_response(conn, 200)
      data = response["data"]

      assert data["location"]["name"] == "Bayern"
      assert data["location"]["slug"] == "bayern"
      assert data["location"]["type"] == "federal_state"
      assert data["year"] == year
      assert data["vacation_days_requested"] == 5
      assert data["variant"] == "normal"
      assert is_map(data["summary"])
      assert is_list(data["optimal_windows"])
      assert is_map(data["links"])
    end

    test "returns results for budget variant", %{conn: conn, bayern: bayern, year: year} do
      conn =
        get(
          conn,
          "/api/v2.1/federal-states/#{bayern.slug}/vacation-optimizer?year=#{year}&days=10&variant=budget"
        )

      response = json_response(conn, 200)
      data = response["data"]
      assert data["variant"] == "budget"
      assert data["vacation_days_requested"] == 10
    end

    test "returns error for missing days parameter", %{conn: conn, bayern: bayern, year: year} do
      conn = get(conn, "/api/v2.1/federal-states/#{bayern.slug}/vacation-optimizer?year=#{year}")

      response = json_response(conn, 400)
      assert is_list(response["errors"])
      assert response["errors"] != []
    end

    test "returns error for invalid days (> 60)", %{conn: conn, bayern: bayern, year: year} do
      conn =
        get(
          conn,
          "/api/v2.1/federal-states/#{bayern.slug}/vacation-optimizer?year=#{year}&days=99"
        )

      response = json_response(conn, 400)
      assert is_list(response["errors"])
    end

    test "returns error for invalid year", %{conn: conn, bayern: bayern} do
      conn =
        get(conn, "/api/v2.1/federal-states/#{bayern.slug}/vacation-optimizer?year=1999&days=10")

      response = json_response(conn, 400)
      assert is_list(response["errors"])
    end

    test "returns 404 for non-existent federal state", %{conn: conn, year: year} do
      conn =
        get(conn, "/api/v2.1/federal-states/non-existent/vacation-optimizer?year=#{year}&days=10")

      assert conn.status == 404
    end

    test "respects top parameter", %{conn: conn, bayern: bayern, year: year} do
      conn =
        get(
          conn,
          "/api/v2.1/federal-states/#{bayern.slug}/vacation-optimizer?year=#{year}&days=10&top=3"
        )

      response = json_response(conn, 200)
      data = response["data"]
      # Should return at most 3 results (or fewer if less available)
      assert length(data["optimal_windows"]) <= 3
    end

    test "includes cross_year_option in response", %{conn: conn, bayern: bayern, year: year} do
      conn =
        get(
          conn,
          "/api/v2.1/federal-states/#{bayern.slug}/vacation-optimizer?year=#{year}&days=10"
        )

      response = json_response(conn, 200)
      data = response["data"]
      # cross_year_option can be null or an object
      assert Map.has_key?(data, "cross_year_option")
    end
  end

  describe "GET /api/v2.1/federal-states/:slug/vacation-optimizer/icalendar" do
    test "returns iCal file for valid parameters", %{conn: conn, bayern: bayern, year: year} do
      conn =
        get(
          conn,
          "/api/v2.1/federal-states/#{bayern.slug}/vacation-optimizer/icalendar?year=#{year}&days=10"
        )

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/calendar; charset=utf-8"]

      # Check for Content-Disposition header with filename
      [content_disposition] = get_resp_header(conn, "content-disposition")
      assert content_disposition =~ "attachment"
      assert content_disposition =~ ".ics"

      # Verify iCal content structure
      body = conn.resp_body
      assert body =~ "BEGIN:VCALENDAR"
      assert body =~ "END:VCALENDAR"
      assert body =~ "PRODID:-//mehr-schulferien.de//Urlaubsplaner//DE"
    end

    test "includes VEVENT entries for optimal windows", %{conn: conn, bayern: bayern, year: year} do
      conn =
        get(
          conn,
          "/api/v2.1/federal-states/#{bayern.slug}/vacation-optimizer/icalendar?year=#{year}&days=10"
        )

      body = conn.resp_body
      # Should have at least one event if there are optimal windows
      if body =~ "BEGIN:VEVENT" do
        assert body =~ "DTSTART"
        assert body =~ "DTEND"
        assert body =~ "SUMMARY:"
        assert body =~ "DESCRIPTION:"
      end
    end

    test "returns error for missing parameters", %{conn: conn, bayern: bayern} do
      conn = get(conn, "/api/v2.1/federal-states/#{bayern.slug}/vacation-optimizer/icalendar")

      # Should return an error (either 400 or no content)
      assert conn.status in [400, 422]
    end

    test "includes budget variant suffix in filename", %{conn: conn, bayern: bayern, year: year} do
      conn =
        get(
          conn,
          "/api/v2.1/federal-states/#{bayern.slug}/vacation-optimizer/icalendar?year=#{year}&days=10&variant=budget"
        )

      [content_disposition] = get_resp_header(conn, "content-disposition")
      assert content_disposition =~ "guenstig"
    end
  end
end
