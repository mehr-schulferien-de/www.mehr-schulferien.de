defmodule MehrSchulferienWeb.BlacklistVerifyLive do
  @moduledoc """
  LiveView for verifying blacklist tokens.

  Users arrive here after clicking the magic link in their email.
  """
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.Blacklist

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case Blacklist.verify_token(token) do
      {:ok, _verification_request} ->
        # Verification successful - redirect directly to create page
        {:ok,
         socket
         |> put_flash(:info, "E-Mail bestätigt. Sie können jetzt Daten sperren.")
         |> push_navigate(to: ~p"/wiki/blacklist/create/#{token}")}

      {:error, :not_found} ->
        {:ok,
         socket
         |> assign(
           page_title: "Ungültiger Link",
           status: :not_found
         )
         |> put_flash(:error, "Dieser Bestätigungslink ist ungültig.")}

      {:error, :expired} ->
        {:ok,
         socket
         |> assign(
           page_title: "Link abgelaufen",
           status: :expired
         )
         |> put_flash(:error, "Dieser Bestätigungslink ist abgelaufen.")}

      {:error, :already_verified} ->
        # Token was already verified, check if it's still valid for entry creation
        verification_request = Blacklist.get_verification_request_by_token(token)

        if verification_request && Blacklist.valid_for_entry_creation?(verification_request) do
          # Still valid - redirect directly to create page
          {:ok,
           socket
           |> push_navigate(to: ~p"/wiki/blacklist/create/#{token}")}
        else
          {:ok,
           socket
           |> assign(
             page_title: "Link abgelaufen",
             status: :expired
           )
           |> put_flash(:error, "Dieser Bestätigungslink ist abgelaufen.")}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <%= case @status do %>
        <% :not_found -> %>
          <div class="text-center">
            <div class="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-red-100 mb-6">
              <svg
                class="h-8 w-8 text-red-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                >
                </path>
              </svg>
            </div>
            <h1 class="text-2xl font-bold text-gray-900 mb-4">Ungültiger Link</h1>
            <p class="text-gray-600 mb-8">
              Dieser Bestätigungslink ist ungültig. Möglicherweise wurde er bereits verwendet
              oder der Link ist fehlerhaft.
            </p>
            <Phoenix.Component.link
              navigate={~p"/wiki/blacklist/request"}
              class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Neuen Link anfordern
            </Phoenix.Component.link>
          </div>
        <% :expired -> %>
          <div class="text-center">
            <div class="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-yellow-100 mb-6">
              <svg
                class="h-8 w-8 text-yellow-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                >
                </path>
              </svg>
            </div>
            <h1 class="text-2xl font-bold text-gray-900 mb-4">Link abgelaufen</h1>
            <p class="text-gray-600 mb-8">
              Dieser Bestätigungslink ist abgelaufen. Bestätigungslinks sind 24 Stunden gültig.
              Bitte fordern Sie einen neuen Link an.
            </p>
            <Phoenix.Component.link
              navigate={~p"/wiki/blacklist/request"}
              class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Neuen Link anfordern
            </Phoenix.Component.link>
          </div>
      <% end %>
    </div>
    """
  end
end
