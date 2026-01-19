defmodule MehrSchulferienWeb.Plugs.AuthPlug do
  @moduledoc """
  Plug to fetch the current user from session.

  This plug reads the session token from cookies and assigns the
  current user to the connection if the token is valid.

  For unauthenticated users accessing wiki routes, this plug also sets
  a return-to cookie so they can be redirected back after login.
  """

  import Plug.Conn

  alias MehrSchulferien.Accounts
  alias MehrSchulferienWeb.Plugs.RequireAuthPlug

  @session_cookie "_mehr_schulferien_wiki_session"

  def init(opts), do: opts

  def call(conn, _opts) do
    token = get_session(conn, :wiki_session_token)

    conn =
      if token do
        case Accounts.get_user_by_session_token(token) do
          nil ->
            conn
            |> delete_session(:wiki_session_token)
            |> assign(:current_user, nil)

          user ->
            assign(conn, :current_user, user)
        end
      else
        assign(conn, :current_user, nil)
      end

    # Set return-to cookie for unauthenticated wiki requests
    if is_nil(conn.assigns[:current_user]) and wiki_path?(conn.request_path) do
      RequireAuthPlug.set_return_to_cookie(conn)
    else
      conn
    end
  end

  defp wiki_path?(path) do
    String.starts_with?(path, "/wiki")
  end

  @doc """
  Sets the session token in the session.
  """
  def put_session_token(conn, token) do
    conn
    |> put_session(:wiki_session_token, token)
    |> configure_session(renew: true)
  end

  @doc """
  Clears the session token from the session.
  """
  def clear_session_token(conn) do
    conn
    |> delete_session(:wiki_session_token)
    |> configure_session(renew: true)
  end

  @doc """
  Returns the session cookie name.
  """
  def session_cookie, do: @session_cookie
end
