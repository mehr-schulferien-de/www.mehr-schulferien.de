defmodule MehrSchulferienWeb.WikiAuth do
  @moduledoc """
  Authentication and authorization hooks for wiki LiveViews.

  Use this module with `on_mount` to require authentication and
  enforce wiki access restrictions (hours, rate limits).
  """

  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 3]

  alias MehrSchulferien.Accounts
  alias MehrSchulferienWeb.Plugs.WikiHoursPlug

  @doc """
  LiveView on_mount hook for wiki authentication.

  ## Actions

  - `:require_auth` - Requires a logged-in wiki user. Redirects to login if not
    authenticated. Shows wiki closed page if outside operating hours (22:00-06:00).

  - `:assign_user` - Optionally assigns the current user without requiring auth.
    Use this for pages that can be viewed by anyone but show different content
    for logged-in users.
  """
  def on_mount(:require_auth, _params, session, socket) do
    socket = assign_current_user(socket, session)

    cond do
      # Check if wiki is closed (night hours)
      WikiHoursPlug.wiki_closed?() ->
        {:halt,
         socket
         |> put_flash(:error, "Das Wiki ist derzeit geschlossen (22:00-06:00 Uhr).")
         |> redirect(to: "/")}

      # Check if user is authenticated
      # The return-to cookie was already set by AuthPlug during the HTTP request
      is_nil(socket.assigns.current_user) ->
        {:halt,
         socket
         |> redirect(to: "/auth/login")}

      # User is authenticated and wiki is open
      true ->
        {:cont, socket}
    end
  end

  def on_mount(:assign_user, _params, session, socket) do
    {:cont, assign_current_user(socket, session)}
  end

  defp assign_current_user(socket, session) do
    case session["wiki_session_token"] do
      nil ->
        assign(socket, :current_user, nil)

      token ->
        user = Accounts.get_user_by_session_token(token)
        assign(socket, :current_user, user)
    end
  end
end
