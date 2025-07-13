defmodule MehrSchulferienWeb.RedirectControllerTest do
  use MehrSchulferienWeb.ConnCase

  describe "cities redirects" do
    test "redirects /cities/:city_slug to /ferien/deutschland/stadt/:city_slug with 301", %{
      conn: conn
    } do
      conn = get(conn, "/cities/33619-bielefeld")
      assert redirected_to(conn, 301) == "/ferien/deutschland/stadt/33619-bielefeld"
    end

    test "redirects /cities/:city_slug/:year to /ferien/deutschland/stadt/:city_slug/:year with 301",
         %{conn: conn} do
      conn = get(conn, "/cities/33619-bielefeld/2025")
      assert redirected_to(conn, 301) == "/ferien/deutschland/stadt/33619-bielefeld/2025"
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
