defmodule MehrSchulferienWeb.AuthVerifyLive do
  @moduledoc """
  LiveView for verifying magic link tokens.

  This view handles the token verification and session creation.
  """
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.Accounts

  @impl true
  def mount(%{"token" => token} = params, _session, socket) do
    return_to = Map.get(params, "return_to", "/wiki")

    if connected?(socket) do
      # Verify token and create session
      case Accounts.verify_login_token(token) do
        {:ok, user} ->
          # Create session token
          {session_token, _token_record} = Accounts.create_session_token(user)

          {:ok,
           socket
           |> assign(
             page_title: "Anmeldung erfolgreich",
             status: :success,
             user: user,
             session_token: session_token,
             return_to: return_to
           )}

        {:error, :not_found} ->
          {:ok,
           socket
           |> assign(
             page_title: "Ungültiger Link",
             status: :error,
             error_message: "Der Anmeldelink ist ungültig oder wurde bereits verwendet."
           )}

        {:error, :expired} ->
          {:ok,
           socket
           |> assign(
             page_title: "Link abgelaufen",
             status: :error,
             error_message:
               "Der Anmeldelink ist abgelaufen. Bitte fordern Sie einen neuen Link an."
           )}

        {:error, :already_used} ->
          {:ok,
           socket
           |> assign(
             page_title: "Link bereits verwendet",
             status: :error,
             error_message:
               "Der Anmeldelink wurde bereits verwendet. Bitte fordern Sie einen neuen Link an."
           )}

        {:error, :banned} ->
          {:ok,
           socket
           |> assign(
             page_title: "Konto gesperrt",
             status: :error,
             error_message: "Ihr Konto wurde gesperrt. Bitte kontaktieren Sie den Support."
           )}
      end
    else
      # Initial mount before websocket connection
      {:ok,
       socket
       |> assign(
         page_title: "Anmeldung wird verarbeitet...",
         status: :loading,
         return_to: return_to
       )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-[60vh] flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full">
        <div class="bg-white dark:bg-gray-800 shadow-lg border border-gray-200 dark:border-gray-700 rounded-lg p-8 text-center">
          <%= case @status do %>
            <% :loading -> %>
              <div class="mx-auto h-16 w-16 bg-blue-100 dark:bg-blue-900/30 rounded-full flex items-center justify-center mb-4">
                <svg
                  class="animate-spin h-8 w-8 text-blue-600 dark:text-blue-400"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    class="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                  >
                  </circle>
                  <path
                    class="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  >
                  </path>
                </svg>
              </div>
              <h2 class="text-xl font-bold text-gray-900 dark:text-gray-100 mb-2">
                Anmeldung wird verarbeitet...
              </h2>
              <p class="text-gray-600 dark:text-gray-400">
                Bitte warten Sie einen Moment.
              </p>
            <% :success -> %>
              <div id="auth-success">
                <div class="mx-auto h-16 w-16 bg-green-100 dark:bg-green-900/30 rounded-full flex items-center justify-center mb-4">
                  <svg
                    class="h-8 w-8 text-green-600 dark:text-green-400"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                </div>
                <h2 class="text-xl font-bold text-gray-900 dark:text-gray-100 mb-2">
                  Anmeldung erfolgreich!
                </h2>
                <p class="text-gray-600 dark:text-gray-400 mb-4">
                  Willkommen zurück! Sie werden weitergeleitet...
                </p>
                <div class="animate-pulse mb-4">
                  <div class="h-2 w-24 mx-auto bg-green-200 dark:bg-green-800 rounded"></div>
                </div>
                <!-- Auto-submit form to create session via controller -->
                <form id="session-form" action="/auth/session" method="post" phx-hook="AutoSubmitForm">
                  <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
                  <input type="hidden" name="token" value={@session_token} />
                  <input type="hidden" name="return_to" value={@return_to} />
                </form>
              </div>
            <% :error -> %>
              <div class="mx-auto h-16 w-16 bg-red-100 dark:bg-red-900/30 rounded-full flex items-center justify-center mb-4">
                <svg
                  class="h-8 w-8 text-red-600 dark:text-red-400"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </div>
              <h2 class="text-xl font-bold text-gray-900 dark:text-gray-100 mb-2">
                {@page_title}
              </h2>
              <p class="text-gray-600 dark:text-gray-400 mb-6">
                {@error_message}
              </p>
              <Phoenix.Component.link
                navigate={~p"/auth/login"}
                class="inline-flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                Neuen Anmeldelink anfordern
              </Phoenix.Component.link>
          <% end %>
        </div>
        
    <!-- Back link -->
        <div class="mt-6 text-center">
          <Phoenix.Component.link
            navigate={~p"/"}
            class="text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200"
          >
            ← Zurück zur Startseite
          </Phoenix.Component.link>
        </div>
      </div>
    </div>
    """
  end
end
