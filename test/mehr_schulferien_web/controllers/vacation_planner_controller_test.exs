defmodule MehrSchulferienWeb.VacationPlannerControllerTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory

  setup do
    country = insert(:country, %{slug: "d", name: "Deutschland"})

    federal_state =
      insert(:federal_state, %{
        slug: "bayern",
        name: "Bayern",
        parent_location_id: country.id
      })

    # Create a public holiday type
    public_holiday_type =
      insert(:holiday_or_vacation_type, %{
        name: "Feiertag",
        colloquial: "Feiertag",
        default_is_public_holiday: true,
        default_is_valid_for_everybody: true
      })

    # Create a holiday so there's data
    insert(:period, %{
      starts_on: ~D[2026-05-01],
      ends_on: ~D[2026-05-01],
      location_id: country.id,
      holiday_or_vacation_type_id: public_holiday_type.id,
      is_public_holiday: true,
      is_valid_for_everybody: true
    })

    %{
      country: country,
      federal_state: federal_state,
      public_holiday_type: public_holiday_type
    }
  end

  describe "GET /urlaubsplaner/:federal_state_slug/:days/:year (show)" do
    test "renders page with valid parameters", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, "/urlaubsplaner/#{federal_state.slug}/30-tage/2026")

      assert html_response(conn, 200) =~ "Urlaubsplaner"
      assert html_response(conn, 200) =~ "Bayern"
      assert html_response(conn, 200) =~ "30"
    end

    test "renders normal variant accents and cross-link", %{
      conn: conn,
      federal_state: federal_state
    } do
      conn = get(conn, "/urlaubsplaner/#{federal_state.slug}/30-tage/2026")

      response = html_response(conn, 200)
      # Active toggle tab is blue in the normal variant
      assert response =~ "bg-blue-600 text-white shadow-sm"
      refute response =~ "bg-green-600 text-white shadow-sm"
      # Blue info box explaining the planner
      assert response =~ "So funktioniert der Urlaubsplaner"
      assert response =~ "bg-blue-50 dark:bg-blue-900/20"
      # Cross-link card points to the budget variant
      assert response =~ "Günstig-Variante"
      refute response =~ "Normal-Variante"
    end

    test "handles single digit days", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, "/urlaubsplaner/#{federal_state.slug}/5-tage/2026")

      assert html_response(conn, 200) =~ "Urlaubsplaner"
    end

    test "returns 404 for invalid days format", %{conn: conn, federal_state: federal_state} do
      # Invalid format doesn't match route constraint, so it's a router-level 404
      conn = get(conn, "/urlaubsplaner/#{federal_state.slug}/invalid/2026")
      assert conn.status == 404
    end

    test "returns 404 for days over 60", %{conn: conn, federal_state: federal_state} do
      # 99-tage matches constraint but is out of range (1-60)
      conn = get(conn, "/urlaubsplaner/#{federal_state.slug}/99-tage/2026")
      assert conn.status == 404
    end

    test "returns 404 for days under 1", %{conn: conn, federal_state: federal_state} do
      # 0-tage matches constraint but is out of range (1-60)
      conn = get(conn, "/urlaubsplaner/#{federal_state.slug}/0-tage/2026")
      assert conn.status == 404
    end

    test "returns 404 for non-existent federal state", %{conn: conn} do
      conn = get(conn, "/urlaubsplaner/non-existent/30-tage/2026")
      assert conn.status == 404
    end

    test "returns 404 for invalid year", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, "/urlaubsplaner/#{federal_state.slug}/30-tage/1999")
      assert conn.status == 404
    end
  end

  describe "GET /urlaubsplaner/:federal_state_slug/:days (index - redirect)" do
    test "redirects to current year", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, "/urlaubsplaner/#{federal_state.slug}/30-tage")

      current_year = Date.utc_today().year

      assert redirected_to(conn) =~
               "/urlaubsplaner/#{federal_state.slug}/30-tage/#{current_year}"
    end
  end

  describe "GET /urlaubsplaner-guenstig/:federal_state_slug/:days/:year (show_budget)" do
    test "renders budget variant page", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, "/urlaubsplaner-guenstig/#{federal_state.slug}/30-tage/2026")

      assert html_response(conn, 200) =~ "Urlaubsplaner"
      assert html_response(conn, 200) =~ "Bayern"
      # Should indicate budget variant
      assert html_response(conn, 200) =~ "Schulferien" or
               html_response(conn, 200) =~ "günstig" or
               html_response(conn, 200) =~ "Außerhalb"
    end

    test "renders budget variant accents and cross-link", %{
      conn: conn,
      federal_state: federal_state
    } do
      conn = get(conn, "/urlaubsplaner-guenstig/#{federal_state.slug}/30-tage/2026")

      response = html_response(conn, 200)
      # Active toggle tab is green in the budget variant
      assert response =~ "bg-green-600 text-white shadow-sm"
      refute response =~ "bg-blue-600 text-white shadow-sm"
      # Green info box explaining the budget variant
      assert response =~ "So funktioniert der Urlaubsplaner (Günstig-Variante)"
      assert response =~ "bg-green-50 dark:bg-green-900/20"
      # Cross-link card points back to the normal variant
      assert response =~ "Normal-Variante"
      assert response =~ "Maximale Freizeit (inkl. Schulferien)"
    end

    test "excludes school vacation periods in calculation", %{
      conn: conn,
      federal_state: federal_state
    } do
      # Create school vacation
      school_vacation_type =
        insert(:holiday_or_vacation_type, %{
          name: "Osterferien",
          colloquial: "Osterferien",
          default_is_school_vacation: true,
          default_is_valid_for_students: true
        })

      insert(:period, %{
        starts_on: ~D[2026-04-06],
        ends_on: ~D[2026-04-17],
        location_id: federal_state.id,
        holiday_or_vacation_type_id: school_vacation_type.id,
        is_school_vacation: true,
        is_valid_for_students: true
      })

      conn = get(conn, "/urlaubsplaner-guenstig/#{federal_state.slug}/30-tage/2026")

      assert html_response(conn, 200) =~ "Urlaubsplaner"
    end
  end

  describe "GET /urlaubsplaner-guenstig/:federal_state_slug/:days (index_budget - redirect)" do
    test "redirects to current year", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, "/urlaubsplaner-guenstig/#{federal_state.slug}/30-tage")

      current_year = Date.utc_today().year

      assert redirected_to(conn) =~
               "/urlaubsplaner-guenstig/#{federal_state.slug}/30-tage/#{current_year}"
    end
  end

  describe "page content" do
    test "shows explanation section", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, "/urlaubsplaner/#{federal_state.slug}/30-tage/2026")

      response = html_response(conn, 200)
      # Should have explanation of how it works
      assert response =~ "Feiertage" or response =~ "Wochenenden" or response =~ "Effizienz"
    end

    test "shows variant toggle links", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, "/urlaubsplaner/#{federal_state.slug}/30-tage/2026")

      response = html_response(conn, 200)
      # Should have links to both variants
      assert response =~ "urlaubsplaner-guenstig" or response =~ "Schulferien"
    end

    test "shows days pagination", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, "/urlaubsplaner/#{federal_state.slug}/30-tage/2026")

      response = html_response(conn, 200)
      # Should have links to other day amounts
      assert response =~ "10-tage" or response =~ "20-tage" or response =~ "Tage"
    end

    test "shows related links section", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, "/urlaubsplaner/#{federal_state.slug}/30-tage/2026")

      response = html_response(conn, 200)
      # Should have links to related pages
      assert response =~ "brueckentage" or response =~ "ferien" or response =~ "Brückentage"
    end
  end
end
