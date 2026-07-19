defmodule MehrSchulferienWeb.RobotsSystemTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest

  describe "robots.txt" do
    test "returns 200 with the static crawl rules", %{conn: conn} do
      conn = get(conn, "/robots.txt")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]

      response = response(conn, 200)
      assert response =~ "User-agent: *"
      assert response =~ "Disallow: /api"
      assert response =~ "Disallow: /users"
      assert response =~ "Disallow: /sessions"
      assert response =~ "Disallow: /password_resets"
      assert response =~ "Disallow: /admin"
      assert response =~ "Disallow: /wiki"
      assert response =~ "Disallow: /ads"
      assert response =~ "Disallow: /ferien/*/schule/*/vcard"
      assert response =~ "Disallow: /schule/*/vcard"
      assert response =~ "Sitemap: https://www.mehr-schulferien.de/sitemap.xml"
    end

    test "does not block redirected URLs (year pages, legacy /land/ routes)", %{conn: conn} do
      # Year-suffixed city/school/state/bridge-day URLs and legacy /land/
      # routes 301 to their evergreen replacements. Blocking them in
      # robots.txt would prevent crawlers from ever seeing those redirects,
      # leaving the URLs stuck in the search index forever (GSC showed
      # ~107k URLs in that limbo).
      response = conn |> get("/robots.txt") |> response(200)

      refute response =~ ~r{Disallow: /ferien/\*/stadt/}
      refute response =~ ~r{Disallow: /ferien/\*/schule/\*/20}
      refute response =~ ~r{Disallow: /brueckentage/}
      refute response =~ "Disallow: /land"
    end
  end
end
