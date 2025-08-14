defmodule MehrSchulferienWeb.CityControllerTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory

  describe "show/2" do
    setup do
      # Create base location hierarchy
      country = insert(:country, slug: "d", name: "Deutschland")

      federal_state =
        insert(:federal_state, parent_location_id: country.id, slug: "bayern", name: "Bayern")

      county =
        insert(:county, parent_location_id: federal_state.id, slug: "muenchen", name: "München")

      city = insert(:city, parent_location_id: county.id, slug: "muenchen-stadt", name: "München")

      {:ok, country: country, federal_state: federal_state, county: county, city: city}
    end

    test "returns 404 when no vacation data exists", %{conn: conn, city: city} do
      # No periods exist, so should return 404
      conn = get(conn, "/ferien/d/stadt/#{city.slug}")

      assert html_response(conn, 404)
    end

    test "returns 200 when vacation data exists", %{
      conn: conn,
      country: country,
      federal_state: federal_state,
      city: city
    } do
      # Create a vacation type
      vacation_type =
        insert(:holiday_or_vacation_type,
          slug: "sommer",
          name: "Sommerferien",
          default_is_school_vacation: true,
          country_location_id: country.id
        )

      # Create a public holiday type
      holiday_type =
        insert(:holiday_or_vacation_type,
          slug: "neujahr",
          name: "Neujahr",
          default_is_public_holiday: true,
          default_is_school_vacation: false,
          country_location_id: country.id
        )

      # Create a vacation period
      insert(:period,
        location_id: federal_state.id,
        holiday_or_vacation_type_id: vacation_type.id,
        starts_on: Date.utc_today(),
        ends_on: Date.add(Date.utc_today(), 14),
        is_school_vacation: true,
        is_valid_for_students: true
      )

      # Create a public holiday for FAQ
      insert(:period,
        location_id: federal_state.id,
        holiday_or_vacation_type_id: holiday_type.id,
        starts_on: Date.add(Date.utc_today(), 30),
        ends_on: Date.add(Date.utc_today(), 30),
        is_public_holiday: true,
        is_valid_for_everybody: true
      )

      conn = get(conn, "/ferien/d/stadt/#{city.slug}")

      assert html_response(conn, 200)
    end

    test "redirects year-specific URLs to non-year URL", %{conn: conn, city: city} do
      conn = get(conn, "/ferien/d/stadt/#{city.slug}/2024")

      assert redirected_to(conn, 301) == "/ferien/d/stadt/#{city.slug}"
    end
  end
end
