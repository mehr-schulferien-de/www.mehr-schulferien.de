defmodule MehrSchulferienWeb.VacationControllerTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory

  describe "show/2" do
    setup do
      # Create base data
      country = insert(:country, slug: "d", name: "Deutschland")

      federal_state =
        insert(:federal_state,
          parent_location_id: country.id,
          slug: "niedersachsen",
          name: "Niedersachsen"
        )

      # Create vacation type
      vacation_type =
        insert(:holiday_or_vacation_type,
          slug: "oster",
          name: "Ostern",
          colloquial: "Osterferien",
          default_is_school_vacation: true,
          country_location_id: country.id
        )

      {:ok, country: country, federal_state: federal_state, vacation_type: vacation_type}
    end

    test "returns 404 when vacation period does not exist for the year", %{
      conn: conn,
      federal_state: federal_state,
      vacation_type: vacation_type
    } do
      # Create a vacation period for 2024, but we'll test for 2016 where it doesn't exist
      insert(:period,
        location_id: federal_state.id,
        holiday_or_vacation_type_id: vacation_type.id,
        starts_on: ~D[2024-03-25],
        ends_on: ~D[2024-04-05],
        is_school_vacation: true
      )

      # Request a year where the vacation doesn't exist
      conn = get(conn, "/osterferien/niedersachsen/2016")

      assert html_response(conn, 404)
      # Check that the page still renders with the "no data" message
      assert html_response(conn, 404) =~ "werden in der Regel"
    end

    test "returns 200 when vacation period exists for the year", %{
      conn: conn,
      federal_state: federal_state,
      vacation_type: vacation_type
    } do
      # Create a vacation period for 2024
      insert(:period,
        location_id: federal_state.id,
        holiday_or_vacation_type_id: vacation_type.id,
        starts_on: ~D[2024-03-25],
        ends_on: ~D[2024-04-05],
        is_school_vacation: true,
        is_valid_for_students: true,
        is_valid_for_everybody: false,
        is_public_holiday: false
      )

      # Request the year where the vacation exists
      conn = get(conn, "/osterferien/niedersachsen/2024")

      response = html_response(conn, 200)
      # Check that the actual vacation dates are shown (in meta tag at least)
      assert response =~ "25.03.-05.04.2024"
    end

    test "redirects when vacation type doesn't exist at all", %{conn: conn} do
      # Try to access a vacation type that doesn't exist
      conn = get(conn, "/fantasieferien/niedersachsen/2024")

      # Should redirect to federal state page
      assert redirected_to(conn) == "/ferien/d/bundesland/niedersachsen/2024"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Diese Ferienart existiert nicht"
    end

    test "redirects when vacation type exists but not for this state", %{
      conn: conn,
      country: country
    } do
      # Create a vacation type that exists but has no periods for this state
      _unused_vacation_type =
        insert(:holiday_or_vacation_type,
          slug: "herbst",
          name: "Herbstferien",
          colloquial: "Herbstferien",
          default_is_school_vacation: true,
          country_location_id: country.id
        )

      # Try to access it
      conn = get(conn, "/herbstferien/niedersachsen/2024")

      # Should redirect to federal state page
      assert redirected_to(conn) == "/ferien/d/bundesland/niedersachsen/2024"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "gibt es in Niedersachsen nicht"
    end
  end

  describe "vacation_current/2" do
    test "redirects to current year", %{conn: conn} do
      # Mock today's date
      today = Date.utc_today()

      conn = get(conn, "/osterferien/niedersachsen")

      assert redirected_to(conn) == "/osterferien/niedersachsen/#{today.year}"
    end
  end
end
