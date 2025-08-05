defmodule MehrSchulferienWeb.Plugs.CorsPlug do
  @moduledoc """
  A plug to handle Cross-Origin Resource Sharing (CORS).

  This plug adds the necessary headers to allow API requests from browser applications.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "accept, content-type")
    |> put_resp_header("access-control-max-age", "3600")
    |> handle_preflight()
  end

  defp handle_preflight(%{method: "OPTIONS"} = conn) do
    conn
    |> send_resp(200, "")
    |> halt()
  end

  defp handle_preflight(conn), do: conn
end
