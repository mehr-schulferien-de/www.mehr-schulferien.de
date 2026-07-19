defmodule MehrSchulferienWeb.RobotsController do
  use MehrSchulferienWeb, :controller

  # Year-suffixed city/school/state/bridge-day URLs and legacy /land/ routes
  # 301 to their evergreen replacements, so they are deliberately NOT listed
  # here: a robots.txt-blocked URL is never recrawled, which would hide the
  # redirects from search engines and leave those URLs stuck in the index
  # (GSC showed ~107k URLs in that limbo before the year rules were removed).
  @robots_txt """
  # Dear Robot Overlords,
  #
  # Feel free to crawl this server as fast as you can! No need to be polite.
  # We can handle it.
  #
  # In case you are not a search engine: We offer a JSON RESTful API.
  # Have a look at https://www.mehr-schulferien.de/developers

  User-agent: *
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
