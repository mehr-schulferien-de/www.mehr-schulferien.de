defmodule MehrSchulferienWeb.Api.V21.QueryControllerTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory

  setup do
    # Create test data
    country = insert(:country, %{name: "Deutschland", slug: "deutschland"})

    federal_state =
      insert(:federal_state, %{name: "Bayern", slug: "bayern", parent_location_id: country.id})

    # Create a public holiday
    new_year_type =
      insert(:holiday_or_vacation_type, %{
        name: "Neujahr",
        slug: "neujahr",
        default_is_public_holiday: true,
        default_is_school_vacation: false,
        country_location_id: country.id
      })

    new_year_day = Date.new!(2025, 1, 1)

    insert(:period, %{
      location_id: federal_state.id,
      holiday_or_vacation_type_id: new_year_type.id,
      starts_on: new_year_day,
      ends_on: new_year_day,
      is_public_holiday: true,
      is_school_vacation: false,
      is_valid_for_everybody: true,
      is_valid_for_students: false
    })

    %{federal_state: federal_state, new_year_day: new_year_day}
  end

  describe "GET /api/v2.1/queries/is-public-holiday" do
    test "returns true for public holiday", %{
      conn: conn,
      federal_state: federal_state,
      new_year_day: new_year_day
    } do
      conn =
        get(
          conn,
          "/api/v2.1/queries/is-public-holiday?location_slug=#{federal_state.slug}&date=#{Date.to_iso8601(new_year_day)}"
        )

      response = json_response(conn, 200)
      data = response["data"]

      assert data["is_public_holiday"] == true
      assert data["location"]["slug"] == federal_state.slug
      assert length(data["holidays"]) == 1
      assert hd(data["holidays"])["name"] == "Neujahr"
    end

    test "answers for a slug shared by several locations", %{
      conn: conn,
      federal_state: federal_state,
      new_year_day: new_year_day
    } do
      # A city can carry a federal state's slug, and the ambiguous lookup used
      # to blow up with Ecto.MultipleResultsError, so the endpoint returned 500
      # for ?location_slug=hessen while unique slugs answered fine.
      county = insert(:county, %{parent_location_id: federal_state.id})
      _namesake_city = insert(:city, %{slug: federal_state.slug, parent_location_id: county.id})

      conn =
        get(
          conn,
          "/api/v2.1/queries/is-public-holiday?location_slug=#{federal_state.slug}&date=#{Date.to_iso8601(new_year_day)}"
        )

      response = json_response(conn, 200)
      assert response["data"]["is_public_holiday"] == true
    end

    test "returns false for regular day", %{conn: conn, federal_state: federal_state} do
      conn =
        get(
          conn,
          "/api/v2.1/queries/is-public-holiday?location_slug=#{federal_state.slug}&date=2025-09-15"
        )

      response = json_response(conn, 200)
      data = response["data"]

      assert data["is_public_holiday"] == false
      assert data["location"]["slug"] == federal_state.slug
      assert data["holidays"] == []
    end

    test "uses today as default date", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, "/api/v2.1/queries/is-public-holiday?location_slug=#{federal_state.slug}")
      response = json_response(conn, 200)
      data = response["data"]

      assert Map.has_key?(data, "is_public_holiday")
      assert Map.has_key?(data, "date")
    end

    test "returns error for unknown location", %{conn: conn} do
      conn = get(conn, "/api/v2.1/queries/is-public-holiday?location_slug=unknown")
      assert json_response(conn, 404)
    end

    test "returns error for invalid date", %{conn: conn, federal_state: federal_state} do
      conn =
        get(
          conn,
          "/api/v2.1/queries/is-public-holiday?location_slug=#{federal_state.slug}&date=invalid"
        )

      assert json_response(conn, 400)
    end
  end

  describe "GET /api/v2.1/queries/is-school-day" do
    test "returns true for regular school day", %{conn: conn, federal_state: federal_state} do
      conn =
        get(
          conn,
          "/api/v2.1/queries/is-school-day?location_slug=#{federal_state.slug}&date=2025-09-15"
        )

      response = json_response(conn, 200)
      data = response["data"]

      assert data["is_school_day"] == true
      assert data["location"]["slug"] == federal_state.slug
      assert data["school_free_periods"] == []
    end

    test "returns false for weekend", %{conn: conn, federal_state: federal_state} do
      conn =
        get(
          conn,
          "/api/v2.1/queries/is-school-day?location_slug=#{federal_state.slug}&date=2025-12-27"
        )

      response = json_response(conn, 200)
      data = response["data"]

      assert data["is_school_day"] == false
      assert data["location"]["slug"] == federal_state.slug
    end

    test "uses today as default date", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, "/api/v2.1/queries/is-school-day?location_slug=#{federal_state.slug}")
      response = json_response(conn, 200)
      data = response["data"]

      assert Map.has_key?(data, "is_school_day")
      assert Map.has_key?(data, "date")
    end

    test "returns error for unknown location", %{conn: conn} do
      conn = get(conn, "/api/v2.1/queries/is-school-day?location_slug=unknown")
      assert json_response(conn, 404)
    end
  end

  describe "GET /api/v2.1/queries/check-date" do
    test "returns comprehensive date status", %{
      conn: conn,
      federal_state: federal_state,
      new_year_day: new_year_day
    } do
      conn =
        get(
          conn,
          "/api/v2.1/queries/check-date?location_slug=#{federal_state.slug}&date=#{Date.to_iso8601(new_year_day)}"
        )

      response = json_response(conn, 200)
      data = response["data"]

      assert data["is_public_holiday"] == true
      assert data["is_school_day"] == false
      assert data["is_weekend"] == false
      assert Map.has_key?(data, "is_school_vacation")
      assert Map.has_key?(data, "explanation")
      assert data["location"]["slug"] == federal_state.slug
      assert length(data["public_holidays"]) == 1
    end

    test "uses today as default date", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, "/api/v2.1/queries/check-date?location_slug=#{federal_state.slug}")
      response = json_response(conn, 200)
      data = response["data"]

      assert Map.has_key?(data, "is_public_holiday")
      assert Map.has_key?(data, "is_school_day")
      assert Map.has_key?(data, "is_school_vacation")
      assert Map.has_key?(data, "is_weekend")
      assert Map.has_key?(data, "explanation")
    end

    test "returns error for unknown location", %{conn: conn} do
      conn = get(conn, "/api/v2.1/queries/check-date?location_slug=unknown")
      assert json_response(conn, 404)
    end
  end
end
