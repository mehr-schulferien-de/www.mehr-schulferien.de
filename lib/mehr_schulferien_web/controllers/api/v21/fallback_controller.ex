defmodule MehrSchulferienWeb.Api.V21.FallbackController do
  @moduledoc """
  Fallback controller for API v2.1 error handling.

  Provides consistent error responses for common error cases.
  """
  use MehrSchulferienWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(MehrSchulferienWeb.Api.V21.ErrorJSON.render("404.json", %{}))
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(MehrSchulferienWeb.Api.V21.ErrorJSON.render("422.json", %{changeset: changeset}))
  end

  def call(conn, {:error, :bad_request}) do
    conn
    |> put_status(:bad_request)
    |> json(MehrSchulferienWeb.Api.V21.ErrorJSON.render("400.json", %{}))
  end

  def call(conn, {:error, message}) when is_binary(message) do
    conn
    |> put_status(:bad_request)
    |> json(MehrSchulferienWeb.Api.V21.ErrorJSON.render("400.json", %{message: message}))
  end
end
