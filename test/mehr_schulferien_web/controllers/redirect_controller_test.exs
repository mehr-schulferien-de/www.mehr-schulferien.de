defmodule MehrSchulferienWeb.RedirectControllerTest do
  use MehrSchulferienWeb.ConnCase

  describe "cities redirects" do
    @tag skip: "Requires database setup with zip code 33619 mapped to Bielefeld"
    test "redirects /cities/:city_slug to /ferien/deutschland/stadt/:city_slug with 301", %{
      conn: conn
    } do
      # This test would redirect from zip-code-based URL to proper city slug
      # Example: /cities/33619-bielefeld -> /ferien/deutschland/stadt/bielefeld
      conn = get(conn, "/cities/33619-bielefeld")
      assert conn.status == 301
      # The actual redirect location would depend on the city's slug in the database
    end

    @tag skip: "Requires database setup with zip code 33619 mapped to Bielefeld"
    test "redirects /cities/:city_slug/:year to /ferien/deutschland/stadt/:city_slug/:year with 301",
         %{conn: conn} do
      # This test would redirect from zip-code-based URL to proper city slug with year
      # Example: /cities/33619-bielefeld/2025 -> /ferien/deutschland/stadt/bielefeld/2025
      conn = get(conn, "/cities/33619-bielefeld/2025")
      assert conn.status == 301
      # The actual redirect location would depend on the city's slug in the database
    end
  end

  describe "land redirects" do
    test "redirects /land/:country_slug/stadt/:city_slug to /ferien/:country_slug/stadt/:city_slug",
         %{conn: conn} do
      conn = get(conn, "/land/deutschland/stadt/33619-bielefeld")
      assert redirected_to(conn, 302) == "/ferien/deutschland/stadt/33619-bielefeld"
    end

    test "redirects /land/:country_slug/stadt/:city_slug/:year to /ferien/:country_slug/stadt/:city_slug/:year",
         %{conn: conn} do
      conn = get(conn, "/land/deutschland/stadt/33619-bielefeld/2025")
      assert redirected_to(conn, 302) == "/ferien/deutschland/stadt/33619-bielefeld/2025"
    end
  end
end
