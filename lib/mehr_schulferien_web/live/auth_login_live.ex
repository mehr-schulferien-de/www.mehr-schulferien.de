defmodule MehrSchulferienWeb.AuthLoginLive do
  @moduledoc """
  LiveView for wiki login via magic link.

  Users enter their email to receive a magic link for authentication.
  """
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.Accounts

  @impl true
  def mount(_params, _session, socket) do
    ip_address =
      if connected?(socket) do
        peer_data = get_connect_info(socket, :peer_data)
        if peer_data, do: format_ip(peer_data[:address]), else: nil
      else
        nil
      end

    is_dev = Application.get_env(:mehr_schulferien, :env) == :dev

    {:ok,
     socket
     |> assign(
       page_title: "Wiki Anmeldung",
       full_name: "",
       email: "",
       errors: %{},
       submitted: false,
       ip_address: ip_address,
       is_dev: is_dev
     )}
  end

  @impl true
  def handle_event("validate", params, socket) do
    full_name = Map.get(params, "full_name", socket.assigns.full_name)
    email = Map.get(params, "email", socket.assigns.email)
    {:noreply, assign(socket, full_name: full_name, email: email, errors: %{})}
  end

  @impl true
  def handle_event("submit", params, socket) do
    full_name = String.trim(Map.get(params, "full_name", ""))
    email = String.trim(Map.get(params, "email", ""))

    errors = validate_form(full_name, email)

    if map_size(errors) > 0 do
      {:noreply, assign(socket, errors: errors)}
    else
      ip_address = socket.assigns.ip_address

      case Accounts.send_magic_link(email,
             full_name: full_name,
             ip_address: ip_address
           ) do
        {:ok, _user} ->
          {:noreply,
           socket
           |> assign(submitted: true, email: email)
           |> put_flash(:info, "Wir haben Ihnen eine E-Mail mit dem Anmeldelink gesendet.")}

        {:error, :banned} ->
          {:noreply,
           socket
           |> put_flash(:error, "Ihr Konto wurde gesperrt. Bitte kontaktieren Sie den Support.")}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.")}
      end
    end
  end

  defp validate_form(full_name, email) do
    %{}
    |> validate_full_name(full_name)
    |> validate_email(email)
  end

  defp validate_full_name(errors, full_name) when byte_size(full_name) < 2 do
    Map.put(errors, :full_name, "Bitte geben Sie Ihren vollständigen Namen ein (min. 2 Zeichen).")
  end

  defp validate_full_name(errors, _full_name), do: errors

  defp validate_email(errors, email) do
    if String.match?(email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/) do
      errors
    else
      Map.put(errors, :email, "Bitte geben Sie eine gültige E-Mail-Adresse ein.")
    end
  end

  defp format_ip(nil), do: nil
  defp format_ip({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"
  defp format_ip(ip) when is_tuple(ip), do: :inet.ntoa(ip) |> to_string()

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-[60vh] flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8">
        <!-- Flash messages -->
        <%= if Phoenix.Flash.get(@flash, :info) do %>
          <div class="p-4 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
            <p class="text-green-800 dark:text-green-300">
              {Phoenix.Flash.get(@flash, :info)}
            </p>
          </div>
        <% end %>

        <%= if Phoenix.Flash.get(@flash, :error) do %>
          <div class="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
            <p class="text-red-800 dark:text-red-300">
              {Phoenix.Flash.get(@flash, :error)}
            </p>
          </div>
        <% end %>

        <div class="bg-white dark:bg-gray-800 shadow-lg border border-gray-200 dark:border-gray-700 rounded-lg p-8">
          <div class="text-center mb-6">
            <div class="mx-auto h-12 w-12 bg-blue-100 dark:bg-blue-900/30 rounded-full flex items-center justify-center mb-4">
              <svg
                class="h-6 w-6 text-blue-600 dark:text-blue-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                />
              </svg>
            </div>
            <h2 class="text-2xl font-bold text-gray-900 dark:text-gray-100">
              Wiki Anmeldung
            </h2>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-400">
              Geben Sie Ihre E-Mail-Adresse ein, um einen Anmeldelink zu erhalten.
            </p>
          </div>

          <%= if @submitted do %>
            <div class="text-center">
              <div class="w-16 h-16 mx-auto bg-green-100 dark:bg-green-900/30 rounded-full flex items-center justify-center mb-4">
                <svg
                  class="w-8 h-8 text-green-600 dark:text-green-400"
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
              <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100">
                E-Mail wurde versendet
              </h3>
              <p class="mt-2 text-sm text-gray-600 dark:text-gray-400">
                Wir haben einen Anmeldelink an
                <strong class="text-gray-900 dark:text-gray-100">{@email}</strong>
                gesendet.
              </p>
              <div class="mt-4 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg text-left">
                <p class="text-sm text-blue-800 dark:text-blue-300">
                  <strong>Hinweis:</strong> Der Link ist 15 Minuten gültig.
                </p>
                <p class="text-sm text-blue-700 dark:text-blue-400 mt-1">
                  Keine E-Mail erhalten? Prüfen Sie auch Ihren Spam-Ordner.
                </p>
              </div>
              <%= if @is_dev do %>
                <div class="mt-4">
                  <a
                    href="/dev/mailbox"
                    target="_blank"
                    class="inline-flex items-center text-sm font-medium text-purple-600 dark:text-purple-400 hover:text-purple-800 dark:hover:text-purple-300"
                  >
                    <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                      />
                    </svg>
                    Dev Mailbox öffnen
                  </a>
                </div>
              <% end %>
            </div>
          <% else %>
            <form phx-change="validate" phx-submit="submit" class="space-y-4">
              <div>
                <label
                  for="full_name"
                  class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                >
                  Vollständiger Name *
                </label>
                <input
                  type="text"
                  name="full_name"
                  id="full_name"
                  value={@full_name}
                  required
                  autofocus
                  class={"mt-1 block w-full rounded-md border-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500 #{if @errors[:full_name], do: "border-red-500", else: "border-gray-300 dark:border-gray-600"}"}
                  placeholder="z.B. Max Mustermann"
                />
                <%= if @errors[:full_name] do %>
                  <p class="mt-1 text-sm text-red-600 dark:text-red-400">{@errors[:full_name]}</p>
                <% end %>
              </div>

              <div>
                <label
                  for="email"
                  class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                >
                  E-Mail-Adresse *
                </label>
                <input
                  type="email"
                  name="email"
                  id="email"
                  value={@email}
                  required
                  class={"mt-1 block w-full rounded-md border-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500 #{if @errors[:email], do: "border-red-500", else: "border-gray-300 dark:border-gray-600"}"}
                  placeholder="ihre@email.de"
                />
                <%= if @errors[:email] do %>
                  <p class="mt-1 text-sm text-red-600 dark:text-red-400">{@errors[:email]}</p>
                <% end %>
              </div>
              
    <!-- Data Storage Notice -->
              <div class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-4">
                <h3 class="text-sm font-semibold text-amber-900 dark:text-amber-100 mb-2">
                  Datenspeicherung
                </h3>
                <p class="text-sm text-amber-700 dark:text-amber-300">
                  Um das Wiki vor Vandalismus zu schützen, speichern wir folgende Daten:
                </p>
                <ul class="text-sm text-amber-700 dark:text-amber-300 mt-2 space-y-1">
                  <li>• Ihren Namen</li>
                  <li>• Ihre E-Mail-Adresse</li>
                </ul>
              </div>

              <div class="pt-2">
                <button
                  type="submit"
                  class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-white dark:focus:ring-offset-gray-800 focus:ring-blue-500"
                >
                  Anmeldelink senden
                </button>
              </div>
            </form>

            <div class="mt-6 text-center">
              <p class="text-xs text-gray-500 dark:text-gray-400">
                Kein Passwort erforderlich. Sie erhalten einen sicheren Link per E-Mail.
              </p>
            </div>

            <%= if @is_dev do %>
              <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700 text-center">
                <a
                  href="/dev/mailbox"
                  target="_blank"
                  class="inline-flex items-center text-sm font-medium text-purple-600 dark:text-purple-400 hover:text-purple-800 dark:hover:text-purple-300"
                >
                  <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                    />
                  </svg>
                  Dev Mailbox
                </a>
              </div>
            <% end %>
          <% end %>
        </div>
        
    <!-- Back link -->
        <div class="text-center">
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
