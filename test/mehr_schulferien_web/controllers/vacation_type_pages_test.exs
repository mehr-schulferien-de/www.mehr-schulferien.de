defmodule MehrSchulferienWeb.VacationTypePagesTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.TestHelpers

  setup %{conn: conn} do
    # Create test data
    country = get_or_create_deutschland()

    # Create some federal states
    bayern =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "bayern",
        name: "Bayern",
        code: "BY",
        is_federal_state: true
      })

    berlin =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "berlin",
        name: "Berlin",
        code: "BE",
        is_federal_state: true
      })

    # Create vacation types
    sommer_type =
      insert(:holiday_or_vacation_type, %{
        country_location_id: country.id,
        name: "Sommerferien",
        slug: "sommer",
        colloquial: "Sommerferien",
        default_is_school_vacation: true
      })

    ostern_type =
      insert(:holiday_or_vacation_type, %{
        country_location_id: country.id,
        name: "Osterferien",
        slug: "ostern",
        colloquial: "Osterferien",
        default_is_school_vacation: true
      })

    # Create some vacation periods
    insert(:period, %{
      location_id: bayern.id,
      holiday_or_vacation_type: sommer_type,
      starts_on: ~D[2025-07-28],
      ends_on: ~D[2025-09-08],
      is_school_vacation: true
    })

    insert(:period, %{
      location_id: berlin.id,
      holiday_or_vacation_type: sommer_type,
      starts_on: ~D[2025-07-17],
      ends_on: ~D[2025-08-29],
      is_school_vacation: true
    })

    insert(:period, %{
      location_id: bayern.id,
      holiday_or_vacation_type: ostern_type,
      starts_on: ~D[2025-04-14],
      ends_on: ~D[2025-04-26],
      is_school_vacation: true
    })

    {:ok, %{conn: conn}}
  end

  describe "vacation type pages" do
    test "GET /sommerferien shows summer vacation overview", %{conn: conn} do
      conn = get(conn, "/sommerferien")

      assert html_response(conn, 200) =~ "Sommerferien"
      assert html_response(conn, 200) =~ "Bayern"
      assert html_response(conn, 200) =~ "Berlin"
      # Check that the table is rendered even if specific dates might not match
      assert html_response(conn, 200) =~ "Dauer"

      # Check for SEO elements
      assert html_response(conn, 200) =~ "<title>"
      assert html_response(conn, 200) =~ "meta name=\"description\""
      assert html_response(conn, 200) =~ "application/ld+json"
    end

    test "GET /osterferien shows easter vacation overview", %{conn: conn} do
      conn = get(conn, "/osterferien")

      assert html_response(conn, 200) =~ "Osterferien"
      assert html_response(conn, 200) =~ "Bayern"
      # Check that the table is rendered
      assert html_response(conn, 200) =~ "Dauer"

      # Check for SEO elements
      assert html_response(conn, 200) =~ "<title>"
      assert html_response(conn, 200) =~ "meta name=\"description\""
      assert html_response(conn, 200) =~ "application/ld+json"
    end

    test "GET /herbstferien shows fall vacation overview", %{conn: conn} do
      conn = get(conn, "/herbstferien")

      assert html_response(conn, 200) =~ "Herbstferien"
      # Page should render even without data
      assert html_response(conn, 200) =~ "<title>"
    end

    test "GET /weihnachtsferien shows christmas vacation overview", %{conn: conn} do
      conn = get(conn, "/weihnachtsferien")

      assert html_response(conn, 200) =~ "Weihnachtsferien"
      assert html_response(conn, 200) =~ "<title>"
    end

    test "GET /winterferien shows winter vacation overview", %{conn: conn} do
      conn = get(conn, "/winterferien")

      assert html_response(conn, 200) =~ "Winterferien"
      assert html_response(conn, 200) =~ "<title>"
    end

    test "GET /pfingstferien shows pentecost vacation overview", %{conn: conn} do
      conn = get(conn, "/pfingstferien")

      assert html_response(conn, 200) =~ "Pfingstferien"
      assert html_response(conn, 200) =~ "<title>"
    end
  end
end
