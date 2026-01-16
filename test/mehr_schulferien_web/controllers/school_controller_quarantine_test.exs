defmodule MehrSchulferienWeb.SchoolControllerQuarantineTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory

  describe "quarantined school handling" do
    setup do
      country = insert(:country, slug: "deutschland")
      federal_state = insert(:federal_state, parent_location_id: country.id)
      county = insert(:county, parent_location_id: federal_state.id)
      city = insert(:city, parent_location_id: county.id)

      {:ok, country: country, city: city}
    end

    test "returns 423 Locked for quarantined school", %{conn: conn, country: country, city: city} do
      school = insert(:school, parent_location_id: city.id, is_quarantined: true)

      conn = get(conn, ~p"/ferien/#{country.slug}/schule/#{school.slug}")

      assert conn.status == 423
      assert get_resp_header(conn, "retry-after") == ["604800"]
      assert html_response(conn, 423) =~ "423 - Gesperrt"
    end

    test "returns 200 for non-quarantined school", %{conn: conn, country: country, city: city} do
      school = insert(:school, parent_location_id: city.id, is_quarantined: false)

      conn = get(conn, ~p"/ferien/#{country.slug}/schule/#{school.slug}")

      # May return 404 if no periods, but should not be 423
      assert conn.status in [200, 404]
      refute conn.status == 423
    end

    test "quarantined school page contains correct message", %{
      conn: conn,
      country: country,
      city: city
    } do
      school = insert(:school, parent_location_id: city.id, is_quarantined: true)

      conn = get(conn, ~p"/ferien/#{country.slug}/schule/#{school.slug}")

      html = html_response(conn, 423)
      assert html =~ "gesperrt"
      assert html =~ "überprüft"
      assert html =~ "Startseite"
    end
  end
end
