defmodule MehrSchulferienWeb.DateQueryControllerTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory

  setup do
    # Create test data
    country = insert(:country, %{name: "Deutschland", slug: "deutschland"})

    federal_state =
      insert(:federal_state, %{name: "Bayern", slug: "bayern", parent_location_id: country.id})

    %{country: country, federal_state: federal_state}
  end

  describe "GET /ist-heute-feiertag/:federal_state_slug" do
    test "renders page successfully", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, ~p"/ist-heute-feiertag/#{federal_state.slug}")
      assert html_response(conn, 200) =~ "Ist heute ein Feiertag"
      assert html_response(conn, 200) =~ federal_state.name
    end

    test "returns 404 for unknown federal state", %{conn: conn} do
      conn = get(conn, ~p"/ist-heute-feiertag/unknown")
      assert html_response(conn, 404)
    end

    test "handles federal state with same slug as city (like Bremen)", %{
      conn: conn,
      country: country
    } do
      # Create Bremen federal state
      bremen_state =
        insert(:federal_state, %{name: "Bremen", slug: "bremen", parent_location_id: country.id})

      # Create Bremen city (has same slug but is_federal_state: false)
      insert(:city, %{
        name: "Bremen (Stadt)",
        slug: "bremen",
        parent_location_id: bremen_state.id
      })

      # Should return the federal state, not the city
      conn = get(conn, ~p"/ist-heute-feiertag/bremen")
      assert html_response(conn, 200) =~ "Ist heute ein Feiertag"
      assert html_response(conn, 200) =~ "Bremen"
      refute html_response(conn, 200) =~ "Stadt"
    end
  end

  describe "GET /ist-heute-schulfrei/:federal_state_slug" do
    test "renders page successfully", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, ~p"/ist-heute-schulfrei/#{federal_state.slug}")
      assert html_response(conn, 200) =~ "Ist heute schulfrei"
      assert html_response(conn, 200) =~ federal_state.name
    end

    test "returns 404 for unknown federal state", %{conn: conn} do
      conn = get(conn, ~p"/ist-heute-schulfrei/unknown")
      assert html_response(conn, 404)
    end

    test "handles federal state with same slug as city", %{conn: conn, country: country} do
      bremen_state =
        insert(:federal_state, %{name: "Bremen", slug: "bremen", parent_location_id: country.id})

      insert(:city, %{
        name: "Bremen (Stadt)",
        slug: "bremen",
        parent_location_id: bremen_state.id
      })

      conn = get(conn, ~p"/ist-heute-schulfrei/bremen")
      assert html_response(conn, 200) =~ "Ist heute schulfrei"
      assert html_response(conn, 200) =~ "Bremen"
    end
  end

  describe "GET /ist-schultag/:federal_state_slug/:date" do
    test "renders page successfully for valid date", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, ~p"/ist-schultag/#{federal_state.slug}/2025-09-15")
      assert html_response(conn, 200) =~ "Schultag"
      assert html_response(conn, 200) =~ federal_state.name
      assert html_response(conn, 200) =~ "2025"
    end

    test "returns 400 for invalid date format", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, ~p"/ist-schultag/#{federal_state.slug}/invalid-date")
      assert html_response(conn, 400)
    end

    test "returns 404 for unknown federal state", %{conn: conn} do
      conn = get(conn, ~p"/ist-schultag/unknown/2025-09-15")
      assert html_response(conn, 404)
    end

    test "handles federal state with same slug as city", %{conn: conn, country: country} do
      bremen_state =
        insert(:federal_state, %{name: "Bremen", slug: "bremen", parent_location_id: country.id})

      insert(:city, %{
        name: "Bremen (Stadt)",
        slug: "bremen",
        parent_location_id: bremen_state.id
      })

      conn = get(conn, ~p"/ist-schultag/bremen/2025-09-15")
      assert html_response(conn, 200) =~ "Schultag"
      assert html_response(conn, 200) =~ "Bremen"
    end
  end

  describe "GET /ist-feiertag/:federal_state_slug/:date" do
    test "renders page successfully for valid date", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, ~p"/ist-feiertag/#{federal_state.slug}/2025-12-25")
      assert html_response(conn, 200) =~ "Feiertag"
      assert html_response(conn, 200) =~ federal_state.name
      assert html_response(conn, 200) =~ "2025"
    end

    test "returns 400 for invalid date format", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, ~p"/ist-feiertag/#{federal_state.slug}/bad-date")
      assert html_response(conn, 400)
    end

    test "returns 404 for unknown federal state", %{conn: conn} do
      conn = get(conn, ~p"/ist-feiertag/unknown/2025-12-25")
      assert html_response(conn, 404)
    end

    test "handles federal state with same slug as city", %{conn: conn, country: country} do
      bremen_state =
        insert(:federal_state, %{name: "Bremen", slug: "bremen", parent_location_id: country.id})

      insert(:city, %{
        name: "Bremen (Stadt)",
        slug: "bremen",
        parent_location_id: bremen_state.id
      })

      conn = get(conn, ~p"/ist-feiertag/bremen/2025-12-25")
      assert html_response(conn, 200) =~ "Feiertag"
      assert html_response(conn, 200) =~ "Bremen"
    end
  end
end
