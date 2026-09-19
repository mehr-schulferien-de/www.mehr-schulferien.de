defmodule MehrSchulferienWeb.RobotsController do
  use MehrSchulferienWeb, :controller

  # Keep canonical year pages and legacy redirect URLs crawlable: Google
  # must be able to read both useful content and its consolidation signals.
  @robots_txt """
  # Canonical holiday pages are available to search engines.
  # API documentation: https://www.mehr-schulferien.de/developers

  User-agent: *
  # Simulated dates are user tools, not separate search landing pages.
  # Match today as the first query parameter or after another parameter.
  Disallow: /*?today=
  Disallow: /*?*&today=

  # These per-school and combinatorial tools have carried noindex since July 2026.
  # Keep the general letter search page available, including its trailing slash.
  Disallow: /briefe/
  Allow: /briefe/$
  Disallow: /urlaubsplaner/
  Disallow: /urlaubsplaner-guenstig/

  Disallow: /api
  Disallow: /users
  Disallow: /sessions
  Disallow: /password_resets
  Disallow: /admin
  Disallow: /wiki

  # Ad-click tracking redirects, not content (they would skew the stats)
  Disallow: /ads

  # vCard downloads are not useful for search engines
  Disallow: /ferien/*/schule/*/vcard
  Disallow: /schule/*/vcard

  Sitemap: https://www.mehr-schulferien.de/sitemap.xml
  """

  def index(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, @robots_txt)
  end
end
