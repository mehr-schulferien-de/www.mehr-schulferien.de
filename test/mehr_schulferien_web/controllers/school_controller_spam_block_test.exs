defmodule MehrSchulferienWeb.SchoolControllerSpamBlockTest do
  use MehrSchulferienWeb.ConnCase

  import Ecto.Query
  import MehrSchulferien.Factory

  describe "spam attack timeframe blocking" do
    setup do
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)
      county = insert(:county, parent_location_id: federal_state.id)
      city = insert(:city, parent_location_id: county.id)
      {:ok, country: country, city: city}
    end

    test "returns 503 for school updated during spam window", %{
      conn: conn,
      country: country,
      city: city
    } do
      # Create school with updated_at in spam window (2026-01-15 19:35 UTC)
      spam_time = ~N[2026-01-15 19:35:00]
      school = insert(:school, parent_location_id: city.id)

      # Update the school's updated_at directly via Ecto
      MehrSchulferien.Repo.update_all(
        from(l in MehrSchulferien.Locations.Location, where: l.id == ^school.id),
        set: [updated_at: spam_time]
      )

      conn = get(conn, ~p"/ferien/#{country.slug}/schule/#{school.slug}")

      assert conn.status == 503
      assert get_resp_header(conn, "retry-after") == ["259200"]
      assert html_response(conn, 503) =~ "Vorübergehend nicht verfügbar"
    end

    test "returns normal page for school updated before spam window", %{
      conn: conn,
      country: country,
      city: city
    } do
      # Create school with updated_at before spam window
      safe_time = ~N[2026-01-15 18:00:00]
      school = insert(:school, parent_location_id: city.id)

      MehrSchulferien.Repo.update_all(
        from(l in MehrSchulferien.Locations.Location, where: l.id == ^school.id),
        set: [updated_at: safe_time]
      )

      conn = get(conn, ~p"/ferien/#{country.slug}/schule/#{school.slug}")

      # Should not be 503
      assert conn.status != 503
    end

    test "returns normal page for school updated after spam window", %{
      conn: conn,
      country: country,
      city: city
    } do
      # Create school with updated_at after spam window
      after_time = ~N[2026-01-15 21:00:00]
      school = insert(:school, parent_location_id: city.id)

      MehrSchulferien.Repo.update_all(
        from(l in MehrSchulferien.Locations.Location, where: l.id == ^school.id),
        set: [updated_at: after_time]
      )

      conn = get(conn, ~p"/ferien/#{country.slug}/schule/#{school.slug}")

      # Should not be 503
      assert conn.status != 503
    end
  end
end
