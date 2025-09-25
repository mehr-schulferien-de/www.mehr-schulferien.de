defmodule MehrSchulferienWeb.Plugs.VisitorTrackingPlug do
  @moduledoc """
  Plug to track visitor activity for determining ad visibility.
  Updates the visitor tracking cookie on each request.
  """

  import Plug.Conn
  alias MehrSchulferienWeb.AdVisibilityHelper

  def init(opts), do: opts

  def call(conn, _opts) do
    # Track the visit and update cookie
    conn = AdVisibilityHelper.track_visit(conn)

    # Store ad visibility decision in assigns for use in templates
    show_ads = AdVisibilityHelper.show_ads?(conn)

    conn
    |> assign(:show_ads, show_ads)
    |> put_session(:show_ads, show_ads)
  end
end
