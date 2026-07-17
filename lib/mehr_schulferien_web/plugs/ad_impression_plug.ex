defmodule MehrSchulferienWeb.Plugs.AdImpressionPlug do
  @moduledoc """
  Counts one house-ad impression per page view: every GET through the
  browser pipeline shows the ad pill under the page's level-1 heading, so
  the page view is the impression. The click route itself is excluded
  (a click is not a second impression).

  The count is a cast into `MehrSchulferien.Ads.Recorder` — no database
  work happens in the request, and when the Recorder is not running (the
  test environment) the cast is a silent no-op.
  """

  alias MehrSchulferien.Ads

  def init(opts), do: opts

  def call(%Plug.Conn{method: "GET"} = conn, _opts) do
    unless String.starts_with?(conn.request_path, "/ads") do
      Ads.record_impression()
    end

    conn
  end

  def call(conn, _opts), do: conn
end
