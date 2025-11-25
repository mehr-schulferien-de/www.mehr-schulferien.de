defmodule MehrSchulferienWeb.HealthController do
  use MehrSchulferienWeb, :controller

  def index(conn, _params) do
    # Check database connectivity
    case MehrSchulferien.Repo.query("SELECT 1") do
      {:ok, _} ->
        conn
        |> put_status(:ok)
        |> json(%{status: "ok", database: "connected"})

      {:error, _} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{status: "error", database: "disconnected"})
    end
  end
end
