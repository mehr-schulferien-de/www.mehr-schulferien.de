defmodule MehrSchulferienWeb.CountryControllerTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.TestHelpers

  describe "read city data" do
    test "shows info for a specific federal state", %{conn: conn} do
      country = get_or_create_deutschland()
      conn = get(conn, ~p"/ferien/#{country.slug}")
      assert html_response(conn, 200) =~ country.name
    end
  end
end
