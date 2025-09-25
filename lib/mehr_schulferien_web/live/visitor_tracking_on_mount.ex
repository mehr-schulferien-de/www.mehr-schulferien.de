defmodule MehrSchulferienWeb.VisitorTrackingOnMount do
  @moduledoc """
  LiveView on_mount callback for visitor tracking and ad visibility determination.
  """

  import Phoenix.Component, only: [assign: 3]

  def on_mount(:default, _params, session, socket) do
    # Get the visitor tracking cookie from session (passed through the plug)
    # Since we can't directly access cookies in LiveView, we need to rely on
    # the value set by the plug in the session
    show_ads = Map.get(session, "show_ads", true)

    socket = assign(socket, :show_ads, show_ads)

    {:cont, socket}
  end
end
