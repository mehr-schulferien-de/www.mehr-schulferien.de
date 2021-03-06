defmodule MehrSchulferienWeb.Authorize do
  @moduledoc """
  Functions to help with authorization.

  See the [Authorization wiki page](https://github.com/riverrun/phauxth/wiki/Authorization)
  for more information and examples about authorization.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias MehrSchulferienWeb.Router.Helpers, as: Routes

  @doc """
  Plug to only allow authenticated users to access the resource.
  """
  def user_check(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts) do
    need_login(conn)
  end

  def user_check(conn, _opts), do: conn

  @doc """
  Plug to only allow unauthenticated users to access the resource.

  See the session controller for an example.
  """
  def guest_check(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts), do: conn

  def guest_check(%Plug.Conn{assigns: %{current_user: _current_user}} = conn, _opts) do
    conn
    |> put_flash(:error, "Sie müssen sich ausloggen, um diese Seite zu sehen.")
    |> redirect(to: Routes.page_path(conn, :index))
    |> halt()
  end

  @doc """
  Plug to only allow authenticated users with the correct id to access the resource.

  See the user controller for an example.
  """
  def id_check(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts) do
    need_login(conn)
  end

  def id_check(
        %Plug.Conn{params: %{"id" => id}, assigns: %{current_user: current_user}} = conn,
        _opts
      ) do
    if id == to_string(current_user.id) do
      conn
    else
      conn
      |> put_flash(:error, "Sie haben keine Berechtigung für die von Ihnen aufgerufene Webseite.")
      |> redirect(to: Routes.user_path(conn, :show, current_user))
      |> halt()
    end
  end

  defp need_login(conn) do
    conn
    |> put_session(:request_path, current_path(conn))
    |> put_flash(:error, "Sie müssen sich zu erst einloggen.")
    |> redirect(to: Routes.session_path(conn, :new))
    |> halt()
  end
end
