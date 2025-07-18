defmodule MehrSchulferienWeb.Plugs.LocationCookiesPlug do
  @moduledoc """
  Plug to pass location cookies to LiveView session.
  """
  
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    # Extract unified location cookie
    recent_locations = conn.req_cookies["recent_locations"]
    
    # Debug logging
    require Logger
    Logger.info("LocationCookiesPlug - Recent locations: #{inspect(recent_locations)}")
    
    # Store in session for LiveView access
    conn
    |> put_session(:recent_locations, recent_locations)
  end
end