defmodule MehrSchulferienWeb.Plugs.RequireAuthPlug do
  @moduledoc """
  Plug to require authentication for wiki routes.

  Redirects unauthenticated users to the login page with the return path
  stored in a cookie (expires in 15 minutes).

  Also provides shared functions for return-to cookie management used by
  other plugs and controllers.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  @cookie_name "wiki_return_to"
  # 15 minutes in seconds
  @cookie_max_age 15 * 60

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> set_return_to_cookie()
      |> put_flash(:error, "Bitte melden Sie sich an, um das Wiki zu bearbeiten.")
      |> redirect(to: ~p"/auth/login")
      |> halt()
    end
  end

  @doc """
  Returns the cookie name for return_to.
  """
  def cookie_name, do: @cookie_name

  @doc """
  Returns the cookie max age in seconds.
  """
  def cookie_max_age, do: @cookie_max_age

  @doc """
  Sets the return_to cookie with the current path.
  """
  def set_return_to_cookie(conn) do
    put_resp_cookie(conn, @cookie_name, current_path(conn),
      max_age: @cookie_max_age,
      http_only: true
    )
  end

  @doc """
  Builds the current path including query string.
  """
  def current_path(conn) do
    if conn.query_string != "" do
      conn.request_path <> "?" <> conn.query_string
    else
      conn.request_path
    end
  end

  @doc """
  Gets the return_to path from the cookie.
  """
  def get_return_to(conn) do
    conn.cookies[@cookie_name] || "/wiki"
  end

  @doc """
  Deletes the return_to cookie.
  """
  def delete_return_to_cookie(conn) do
    delete_resp_cookie(conn, @cookie_name)
  end
end
