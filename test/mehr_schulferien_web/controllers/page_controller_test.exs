defmodule MehrSchulferienWeb.PageControllerTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.TestHelpers

  setup %{conn: conn} do
    country = get_or_create_deutschland()
    # Insert NRW as required for the teaser
    nrw = insert(:federal_state, %{slug: "nordrhein-westfalen", parent_location_id: country.id})
    # Insert a holiday_or_vacation_type and a period for the current year
    holiday_or_vacation_type =
      insert(:holiday_or_vacation_type, %{country_location_id: country.id})

    year = Date.utc_today().year
    # Insert a period that covers a bridge day in the current year (Thursday)
    # May 1st, 2025 is a Thursday
    start_date = Date.new!(year, 5, 1)
    end_date = start_date
    # Insert a period before the public holiday to create a bridge day
    insert(:period, %{
      holiday_or_vacation_type: nil,
      holiday_or_vacation_type_id: holiday_or_vacation_type.id,
      location_id: nrw.id,
      starts_on: Date.new!(year, 4, 30),
      ends_on: Date.new!(year, 4, 30),
      is_public_holiday: false,
      is_valid_for_everybody: true,
      created_by_email_address: "test@example.com",
      display_priority: 3
    })

    # Insert the public holiday period
    insert(:period, %{
      holiday_or_vacation_type: nil,
      holiday_or_vacation_type_id: holiday_or_vacation_type.id,
      location_id: nrw.id,
      starts_on: start_date,
      ends_on: end_date,
      is_public_holiday: true,
      is_valid_for_everybody: true,
      created_by_email_address: "test@example.com",
      display_priority: 3
    })

    # Insert another federal state with a period for testing the /new route
    bayern = insert(:federal_state, %{slug: "bayern", parent_location_id: country.id})

    # Add a vacation period for Bayern
    insert(:period, %{
      holiday_or_vacation_type: nil,
      holiday_or_vacation_type_id: holiday_or_vacation_type.id,
      location_id: bayern.id,
      starts_on: Date.new!(year, 5, 15),
      ends_on: Date.new!(year, 5, 25),
      is_school_vacation: true,
      created_by_email_address: "test@example.com",
      display_priority: 3
    })

    {:ok, %{conn: conn}}
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    response = html_response(conn, 200)

    # Check that page renders with 200 status code
    assert response

    # Check that it includes the Schulferien title
    assert response =~ "Schulferien Deutschland"

    # Check for federal state content
    assert response =~ "Schulferien Deutschland"

    # Check for vacation-related text on the page
    assert response =~ "Ferientermine"
  end

  test "custom meta tags are generated", %{conn: conn} do
    conn = get(conn, "/")

    # Check for description meta tag
    assert html_response(conn, 200) =~ "Ferien und Feiertage der nächsten"
  end

  test "GET /impressum returns 200", %{conn: conn} do
    conn = get(conn, "/impressum")
    response = html_response(conn, 200)

    # Check that page renders with 200 status code
    assert response

    # Check that it includes the main heading
    assert response =~ "Impressum und Datenschutzerklärung"

    # Check for some content
    assert response =~ "Stefan Wintermeyer"
    assert response =~ "Datenschutzerklärung"
  end

  test "GET /debug returns 200 and shows system info", %{conn: conn} do
    conn = get(conn, "/debug")
    response = html_response(conn, 200)

    # Check that page renders with 200 status code
    assert response

    # Check for Elixir version
    assert response =~ "Elixir Version"
    assert response =~ System.version()

    # Check for Erlang/OTP version
    assert response =~ "Erlang/OTP Version"

    # Check for environment
    assert response =~ "Environment"

    # Check for database status
    assert response =~ "Database Status"
    assert response =~ "Connected"

    # Check for cities and schools counts
    assert response =~ "Cities"
    assert response =~ "Schools"
  end
end
