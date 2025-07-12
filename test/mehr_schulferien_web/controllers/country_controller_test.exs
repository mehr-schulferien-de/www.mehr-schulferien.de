defmodule MehrSchulferienWeb.CountryControllerTest do
  use MehrSchulferienWeb.ConnCase

  describe "read city data" do
    test "shows info for a specific federal state", %{conn: conn} do
      country = insert(:country, %{slug: "d"})
      conn = get(conn, ~p"/ferien/#{country.slug}")
      assert html_response(conn, 200) =~ country.name
    end
  end
end
