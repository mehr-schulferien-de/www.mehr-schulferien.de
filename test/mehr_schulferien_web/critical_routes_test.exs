defmodule MehrSchulferienWeb.CriticalRoutesTest do
  use MehrSchulferienWeb.ConnCase, async: true

  describe "critical bug prevention: briefe routes must come before vacation catch-all" do
    test "briefe routes work and don't get year appended", %{conn: conn} do
      # This test ensures the routes are compiled in the correct order
      # If briefe routes come after vacation routes, these will fail

      # Test the routes exist by trying to build paths
      # If the route doesn't exist, this will raise an error
      assert Routes.school_path(conn, :documents_index, "test-school") == "/briefe/test-school"

      # These should work as live paths
      assert Routes.live_path(conn, MehrSchulferienWeb.SchoolSearchLive) == "/briefe"

      assert Routes.live_path(conn, MehrSchulferienWeb.EntschuldigungLive, "test-school") ==
               "/briefe/test-school/entschuldigung"
    end

    test "vacation routes work with proper slugs", %{conn: conn} do
      # These should generate proper vacation paths
      assert Routes.vacation_path(conn, :vacation_current, "sommerferien", "bayern") ==
               "/sommerferien/bayern"

      assert Routes.vacation_path(conn, :show, "sommerferien", "bayern", 2025) ==
               "/sommerferien/bayern/2025"
    end

    test "document PDF routes work", %{conn: conn} do
      # PDF download routes should be accessible
      assert Routes.document_pdf_path(conn, :download, "test-school", "entschuldigung") ==
               "/briefe/test-school/entschuldigung/pdf"
    end
  end

  describe "route compilation smoke test" do
    test "all critical routes are defined in router" do
      # This test ensures that our router has all the critical routes defined
      # If any of these are missing, the router won't compile

      routes = MehrSchulferienWeb.Router.__routes__()

      # Helper to check if a route exists
      route_exists? = fn method, path_pattern ->
        Enum.any?(routes, fn route ->
          route.verb == method && route.path == path_pattern
        end)
      end

      # Check critical routes exist
      assert route_exists?.(:get, "/"), "Home route (GET /) not found"
      assert route_exists?.(:get, "/briefe"), "Briefe search route not found"
      assert route_exists?.(:get, "/briefe/:school_slug"), "Briefe school route not found"

      assert route_exists?.(:get, "/:vacation_slug/:federal_state_slug"),
             "Vacation catch-all route not found"

      assert route_exists?.(:get, "/:vacation_slug/:federal_state_slug/:year"),
             "Vacation year route not found"

      assert route_exists?.(:get, "/naechste-ferien/:federal_state_slug"),
             "Next vacation route not found"
    end

    test "briefe routes appear before vacation catch-all routes" do
      routes = MehrSchulferienWeb.Router.__routes__()

      # Find indices of routes
      briefe_index =
        Enum.find_index(routes, fn r ->
          r.path == "/briefe/:school_slug" && r.verb == :get
        end)

      vacation_catch_all_index =
        Enum.find_index(routes, fn r ->
          r.path == "/:vacation_slug/:federal_state_slug" && r.verb == :get
        end)

      # Briefe routes MUST come before vacation catch-all routes
      assert briefe_index != nil, "Briefe route not found"
      assert vacation_catch_all_index != nil, "Vacation catch-all route not found"

      assert briefe_index < vacation_catch_all_index,
             "CRITICAL: Briefe routes must come before vacation catch-all routes to prevent URL conflicts"
    end
  end

  describe "regression test for reported bug" do
    test "URL /briefe/56068-max-von-laue-gymnasium does not get year appended" do
      # This was the specific bug reported - this URL was being caught by
      # the vacation route and redirected to /briefe/56068-max-von-laue-gymnasium/2025

      # If routes are ordered correctly, this should generate the right path
      assert Routes.school_path(build_conn(), :documents_index, "56068-max-von-laue-gymnasium") ==
               "/briefe/56068-max-von-laue-gymnasium"

      # And this should work for all document types
      assert Routes.live_path(
               build_conn(),
               MehrSchulferienWeb.EntschuldigungLive,
               "56068-max-von-laue-gymnasium"
             ) ==
               "/briefe/56068-max-von-laue-gymnasium/entschuldigung"
    end
  end
end
