defmodule MehrSchulferienWeb.LocationCookiesOnMount do
  @moduledoc """
  LiveView on_mount callback to inject location cookies into session
  """

  def on_mount(:default, _params, _session, socket) do
    {:cont, socket}
  end
end
