defmodule MehrSchulferienWeb.BridgeDayControllerTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  @current_year Date.utc_today().year

  defp add_state_with_bridge_days(_) do
    country = get_or_create_deutschland()

    federal_state =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "brandenburg",
        name: "Brandenburg"
      })

    add_public_periods(%{location: federal_state})

    {:ok, %{country: country, federal_state: federal_state}}
  end

  describe "evergreen bridge day page (year-less URL)" do
    setup [:add_state_with_bridge_days]

    test "renders a real page instead of redirecting", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn = get(conn, "/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}")

      response = html_response(conn, 200)
      assert response =~ "Brückentage Brandenburg"

      assert response =~
               ~s(rel="canonical" href="https://www.mehr-schulferien.de/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}")
    end

    test "shows the current year's bridge day proposals", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn = get(conn, "/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}")

      response = html_response(conn, 200)
      assert response =~ "#{@current_year}"
      assert response =~ "Brückentag"
    end

    test "does not render a bridge page for an unknown state", %{conn: conn, country: country} do
      conn = get(conn, "/brueckentage/#{country.slug}/bundesland/atlantis")

      # render_not_found_or_empty_database/1: 404 in prod, 503 ("Datenbank
      # ist leer" hint) in dev and test.
      assert conn.status == 503
    end
  end
end
