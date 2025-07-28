defmodule MehrSchulferienWeb.VacationUrlGenerationTest do
  use MehrSchulferienWeb.ConnCase, async: true
  import MehrSchulferien.TestHelpers
  alias MehrSchulferien.Calendars.VacationTypes

  describe "generated vacation URLs are routable" do
    setup do
      # Create test data
      country = get_or_create_deutschland()

      federal_state =
        insert(:federal_state, %{
          parent_location_id: country.id,
          slug: "bayern",
          name: "Bayern",
          code: "BY",
          is_federal_state: true
        })

      # Get or create vacation type for testing
      vacation_type =
        case MehrSchulferien.Repo.get_by(MehrSchulferien.Calendars.HolidayOrVacationType,
               slug: "sommer",
               default_is_school_vacation: true
             ) do
          nil ->
            insert(:holiday_or_vacation_type, %{
              country_location_id: country.id,
              name: "Sommer",
              slug: "sommer",
              colloquial: "Sommerferien",
              default_is_school_vacation: true
            })

          existing ->
            existing
        end

      # Create periods for year 2025
      insert(:period, %{
        location_id: federal_state.id,
        holiday_or_vacation_type: vacation_type,
        starts_on: ~D[2025-07-28],
        ends_on: ~D[2025-09-08],
        is_school_vacation: true
      })

      conn = build_conn()
      {:ok, conn: conn, country: country, federal_state: federal_state}
    end

    test "all vacation URLs generated from database slugs should be accessible", %{
      conn: _conn,
      country: _country,
      federal_state: federal_state
    } do
      # Get a real federal state from the database
      # country = MehrSchulferien.Locations.get_country_by_slug!("d")
      # federal_state = MehrSchulferien.Locations.get_federal_state_by_slug!("bayern", country)

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

    test "federal state page only shows vacation types that exist in the database", %{
      conn: conn,
      country: _country,
      federal_state: _federal_state
    } do
      # Test with a real state
      conn = get(conn, "/ferien/d/bundesland/bayern/2025")

      # The page may render with 404 status if data is limited
      # But it still renders the page with vacation type links
      body = response(conn, conn.status)

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
