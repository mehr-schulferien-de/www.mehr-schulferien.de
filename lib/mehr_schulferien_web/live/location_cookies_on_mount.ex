defmodule MehrSchulferienWeb.LocationCookiesOnMount do
  @moduledoc """
  LiveView on_mount callback to inject location cookies into session
  """

  require Logger

  def on_mount(:default, _params, session, socket) do
    # Log for debugging
    Logger.info("LocationCookiesOnMount - Session: #{inspect(session)}")

    # Continue with the socket unchanged but session data available in mount
    {:cont, socket}
  end
end
