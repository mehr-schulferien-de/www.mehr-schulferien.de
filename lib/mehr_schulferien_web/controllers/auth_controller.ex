defmodule MehrSchulferienWeb.AuthController do
  @moduledoc """
  Controller for authentication actions.

  Handles logout and session management via traditional controller actions
  (as opposed to LiveView for login/verify).
  """
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Accounts
  alias MehrSchulferienWeb.Plugs.AuthPlug
  alias MehrSchulferienWeb.Plugs.RequireAuthPlug

  @doc """
  Logs out the current user by deleting their session token.
  """
  def logout(conn, _params) do
    token = get_session(conn, :wiki_session_token)

    if token do
      Accounts.delete_session_token(token)
    end

    conn
    |> AuthPlug.clear_session_token()
    |> put_flash(:info, "Sie wurden erfolgreich abgemeldet.")
    |> redirect(to: ~p"/")
  end

  @doc """
  Verifies a magic link token and logs the user in.

  This is the target of magic link emails. It:
  1. Verifies the login token
  2. Creates a session
  3. Redirects to the return_to path from cookie (or /wiki by default)
  4. Deletes the return_to cookie
  """
  def verify(conn, %{"token" => token}) do
    # Get return_to from cookie (set when user was redirected to login)
    return_to = RequireAuthPlug.get_return_to(conn)

    # Always delete the return_to cookie regardless of verification result
    conn = RequireAuthPlug.delete_return_to_cookie(conn)

    case Accounts.verify_login_token(token) do
      {:ok, user} ->
        {session_token, _token_record} = Accounts.create_session_token(user)

        conn
        |> AuthPlug.put_session_token(session_token)
        |> put_flash(:info, "Erfolgreich angemeldet.")
        |> redirect(to: return_to)

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Der Anmeldelink ist ungültig oder wurde bereits verwendet.")
        |> redirect(to: ~p"/auth/login")

      {:error, :expired} ->
        conn
        |> put_flash(
          :error,
          "Der Anmeldelink ist abgelaufen. Bitte fordern Sie einen neuen Link an."
        )
        |> redirect(to: ~p"/auth/login")

      {:error, :already_used} ->
        conn
        |> put_flash(
          :error,
          "Der Anmeldelink wurde bereits verwendet. Bitte fordern Sie einen neuen Link an."
        )
        |> redirect(to: ~p"/auth/login")

      {:error, :banned} ->
        conn
        |> put_flash(:error, "Ihr Konto wurde gesperrt. Bitte kontaktieren Sie den Support.")
        |> redirect(to: ~p"/")
    end
  end
end
