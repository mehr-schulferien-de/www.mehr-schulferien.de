defmodule MehrSchulferienWeb.VacationUrlGenerationTest do
  use MehrSchulferienWeb.ConnCase, async: true
  alias MehrSchulferien.Calendars.VacationTypes

  describe "generated vacation URLs are routable" do
    setup do
      conn = build_conn()
      {:ok, conn: conn}
    end

    test "all vacation URLs generated from database slugs should be accessible", %{conn: conn} do
      # Get a real federal state from the database
      country = MehrSchulferien.Locations.get_country_by_slug!("d")
      federal_state = MehrSchulferien.Locations.get_federal_state_by_slug!("bayern", country)

      # Get vacation types from the database - exactly as the application does
      today = ~D[2025-01-11]
      vacation_types = VacationTypes.list_for_federal_state(federal_state, today)

      # For each vacation type in the database, verify the generated URL is routable
      for vacation_type <- vacation_types do
        # This is exactly how the template generates URLs
        url = "/#{vacation_type.slug}ferien/#{federal_state.slug}/2025"

        # Try to access the URL - it should not raise NoRouteError
        conn = build_conn()

        # This will raise Phoenix.Router.NoRouteError if the route doesn't exist
        # We use try/rescue to check if route exists
        try do
          get(conn, url)
          # If we get here, route exists - test passes
        rescue
          Phoenix.Router.NoRouteError ->
            flunk("URL #{url} (from slug '#{vacation_type.slug}') is not routable")
        end
      end
    end

    test "federal state page only shows vacation types that exist in the database", %{conn: conn} do
      # Test with a real state
      conn = get(conn, "/ferien/d/bundesland/bayern/2025")

      body = html_response(conn, 200)

      # The page should generate URLs that match database slugs + "ferien"
      # and all generated URLs should be valid routes
      # This regex finds all vacation links
      vacation_links = Regex.scan(~r/href="\/([a-z-]+ferien)\/bayern\/2025"/, body)

      for [_, vacation_route] <- vacation_links do
        # Each link should be accessible
        conn = build_conn()

        try do
          get(conn, "/#{vacation_route}/bayern/2025")
          # If we get here, route exists - test passes
        rescue
          Phoenix.Router.NoRouteError ->
            flunk("Generated link /#{vacation_route}/bayern/2025 is not routable")
        end
      end
    end
  end
end
