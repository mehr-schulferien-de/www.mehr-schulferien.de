defmodule MehrSchulferienWeb.SchoolController404Test do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Repo

  describe "deleted school returns 404" do
    test "GET /ferien/d/schule/:slug returns 404 for non-existent school", %{conn: conn} do
      # Try to access a non-existent school
      conn = get(conn, ~p"/ferien/d/schule/non-existent-school-slug")

      assert html_response(conn, 404) =~ "404"
      assert html_response(conn, 404) =~ "Die angeforderte Seite wurde nicht gefunden"
      assert html_response(conn, 404) =~ "Zurück zur Startseite"
    end

    test "GET /ferien/d/schule/:slug returns 404 for deleted school", %{conn: conn} do
      # Create and then delete a school to simulate the real scenario
      {:ok, city} =
        %Location{
          name: "Test City",
          slug: "test-city",
          is_city: true
        }
        |> Repo.insert()

      {:ok, school} =
        %Location{
          name: "Test School To Delete",
          slug: "test-school-to-delete",
          is_school: true,
          parent_location_id: city.id
        }
        |> Repo.insert()

      # Delete the school
      {:ok, _} = MehrSchulferien.Locations.delete_school(school)

      # Try to access the deleted school
      conn = get(conn, ~p"/ferien/d/schule/test-school-to-delete")

      # Should get a proper 404 page, not "Datenbank ist leer"
      assert html_response(conn, 404) =~ "404"
      assert html_response(conn, 404) =~ "Die angeforderte Seite wurde nicht gefunden"
      refute html_response(conn, 404) =~ "Datenbank ist leer"
    end

    test "GET /ferien/d/schule/:slug/:year returns 404 for deleted school", %{conn: conn} do
      # Try to access a non-existent school with year
      conn = get(conn, ~p"/ferien/d/schule/deleted-school-slug/2025")

      assert html_response(conn, 404) =~ "404"
      assert html_response(conn, 404) =~ "Die angeforderte Seite wurde nicht gefunden"
      refute html_response(conn, 404) =~ "Datenbank ist leer"
    end
  end
end
