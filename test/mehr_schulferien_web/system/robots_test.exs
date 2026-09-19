defmodule MehrSchulferienWeb.RobotsSystemTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest

  describe "robots.txt" do
    test "blocks repeatedly crawled noindex tools but keeps their public entry point", %{
      conn: conn
    } do
      rules = conn |> get("/robots.txt") |> response(200)

      for path <- [
            "/briefe/12345-beispielschule",
            "/briefe/12345-beispielschule/entschuldigung",
            "/briefe/12345-beispielschule/beurlaubung",
            "/briefe/12345-beispielschule/sportbefreiung",
            "/urlaubsplaner/bayern/10",
            "/urlaubsplaner/bayern/10/2027",
            "/urlaubsplaner-guenstig/bayern/10/2027"
          ] do
        assert disallowed?(rules, path), "Expected tool exclusion: #{path}"
      end

      for path <- ["/briefe", "/briefe/", "/ist-schultag/bayern/2027-01-11"] do
        refute disallowed?(rules, path), "Unexpected exclusion: #{path}"
      end
    end

    test "blocks simulated dates regardless of query parameter order", %{conn: conn} do
      rules = conn |> get("/robots.txt") |> response(200)

      for path <- [
            "/?today=19.09.2026",
            "/ferien/d/bundesland/bayern?today=19.09.2026",
            "/weihnachtsferien/2027?days=90&today=19.09.2026&view=calendar",
            "/ferien/d/stadt/muenchen?utm_source=test&today="
          ] do
        assert disallowed?(rules, path), "Expected robots exclusion: #{path}"
      end
    end

    test "keeps search landing pages, redirects and rendering assets crawlable", %{conn: conn} do
      rules = conn |> get("/robots.txt") |> response(200)

      for path <- [
            "/",
            "/ferien/d/bundesland/bayern",
            "/ferien/d/bundesland/bayern/2027",
            "/weihnachtsferien/2027",
            "/weihnachtsferien/bayern/2027",
            "/ferien/d/stadt/muenchen/2026",
            "/land/d/stadt/muenchen/2026",
            "/ist-heute-schulfrei/bayern",
            "/briefe",
            "/ferien-widget",
            "/assets/app.css",
            "/assets/app.js",
            "/sitemap-bundeslaender.xml",
            "/ferien/d/bundesland/bayern?utm_source=today",
            "/ferien/d/bundesland/bayern?not_today=19.09.2026"
          ] do
        refute disallowed?(rules, path), "Unexpected robots exclusion: #{path}"
      end
    end

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

  # Google matches case-sensitive URL paths including the query string.
  # Our single group uses wildcards, end anchors and longest-match Allow precedence.
  defp disallowed?(rules, path) do
    rules
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, ["Disallow: ", "Allow: "]))
    |> Enum.flat_map(fn line ->
      [directive, original] = String.split(line, ": ", parts: 2)
      anchored = String.ends_with?(original, "$")
      pattern = if anchored, do: String.trim_trailing(original, "$"), else: original
      regex = pattern |> String.split("*") |> Enum.map_join(".*", &Regex.escape/1)
      regex = "^" <> regex <> if(anchored, do: "$", else: "")

      if Regex.match?(Regex.compile!(regex), path),
        do: [{byte_size(original), directive == "Allow", directive}],
        else: []
    end)
    |> Enum.max(fn -> {0, true, "Allow"} end)
    |> elem(2)
    |> Kernel.==("Disallow")
  end
end
