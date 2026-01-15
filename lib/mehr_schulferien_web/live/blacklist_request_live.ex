defmodule MehrSchulferienWeb.BlacklistRequestLive do
  @moduledoc """
  LiveView for requesting blacklist verification.

  Users enter their name and email to receive a magic link for verification.
  """
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.{Blacklist, Email, Mailer}

  @impl true
  def mount(_params, _session, socket) do
    # Get client info during mount (only available when connected)
    {ip_address, user_agent} =
      if connected?(socket) do
        peer_data = get_connect_info(socket, :peer_data)
        ip = if peer_data, do: format_ip(peer_data[:address]), else: nil
        ua = get_connect_info(socket, :user_agent)
        {ip, ua}
      else
        {nil, nil}
      end

    is_dev = Application.get_env(:mehr_schulferien, :env) == :dev

    {:ok,
     socket
     |> assign(
       page_title: "Datensperrliste - Antrag",
       form_data: %{full_name: "", email: ""},
       errors: %{},
       submitted: false,
       ip_address: ip_address,
       user_agent: user_agent,
       is_dev: is_dev
     )}
  end

  @impl true
  def handle_event("validate", %{"form" => form_params}, socket) do
    form_data = %{
      full_name: Map.get(form_params, "full_name", ""),
      email: Map.get(form_params, "email", "")
    }

    {:noreply, assign(socket, form_data: form_data, errors: %{})}
  end

  @impl true
  def handle_event("submit", %{"form" => form_params}, socket) do
    full_name = String.trim(Map.get(form_params, "full_name", ""))
    email = String.trim(Map.get(form_params, "email", ""))

    errors = validate_form(full_name, email)

    if map_size(errors) > 0 do
      {:noreply, assign(socket, errors: errors)}
    else
      # Use client info stored during mount
      ip_address = socket.assigns.ip_address
      user_agent = socket.assigns.user_agent

      case Blacklist.create_verification_request(
             %{full_name: full_name, email: email},
             ip_address: ip_address,
             user_agent: user_agent
           ) do
        {:ok, _request, raw_token} ->
          # Send verification email
          Email.blacklist_verification_email(email, full_name, raw_token)
          |> Mailer.deliver()

          {:noreply,
           socket
           |> assign(submitted: true, form_data: %{full_name: full_name, email: email})
           |> put_flash(:info, "Wir haben Ihnen eine E-Mail zur Bestätigung gesendet.")}

        {:error, :rate_limited} ->
          {:noreply,
           socket
           |> put_flash(
             :error,
             "Sie haben zu viele Anfragen gestellt. Bitte versuchen Sie es später erneut."
           )}

        {:error, changeset} ->
          errors = format_changeset_errors(changeset)
          {:noreply, assign(socket, errors: errors)}
      end
    end
  end

  defp validate_form(full_name, email) do
    errors = %{}

    errors =
      if String.length(full_name) < 2 do
        Map.put(
          errors,
          :full_name,
          "Bitte geben Sie Ihren vollständigen Namen ein (min. 2 Zeichen)."
        )
      else
        errors
      end

    errors =
      if not String.match?(email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/) do
        Map.put(errors, :email, "Bitte geben Sie eine gültige E-Mail-Adresse ein.")
      else
        errors
      end

    errors
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.into(%{}, fn {k, v} -> {k, Enum.join(v, ", ")} end)
  end

  defp format_ip(nil), do: nil
  defp format_ip({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"
  defp format_ip(ip) when is_tuple(ip), do: :inet.ntoa(ip) |> to_string()

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-6">
      <!-- Flash messages -->
      <%= if Phoenix.Flash.get(@flash, :info) do %>
        <div class="mb-4 p-4 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
          <p class="text-green-800 dark:text-green-300">
            {Phoenix.Flash.get(@flash, :info)}
          </p>
        </div>
      <% end %>

      <%= if Phoenix.Flash.get(@flash, :error) do %>
        <div class="mb-4 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
          <p class="text-red-800 dark:text-red-300">
            {Phoenix.Flash.get(@flash, :error)}
          </p>
        </div>
      <% end %>
      
    <!-- Header -->
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-2">
          Datensperrliste (Blacklist)
        </h1>
        <p class="text-gray-600 dark:text-gray-400">
          Beantragen Sie die Sperrung bestimmter Kontaktdaten auf unserer Website.
        </p>
      </div>

      <%= if @submitted do %>
        <div class="bg-white dark:bg-gray-800 shadow-sm border border-gray-200 dark:border-gray-700 rounded-lg p-6">
          <div class="flex items-start">
            <div class="flex-shrink-0">
              <div class="w-12 h-12 bg-green-100 dark:bg-green-900/30 rounded-full flex items-center justify-center">
                <svg
                  class="w-6 h-6 text-green-600 dark:text-green-400"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M5 13l4 4L19 7"
                  >
                  </path>
                </svg>
              </div>
            </div>
            <div class="ml-4">
              <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100">
                E-Mail wurde versendet
              </h2>
              <p class="text-gray-600 dark:text-gray-400 mt-2">
                Wir haben eine E-Mail an
                <strong class="text-gray-900 dark:text-gray-100">{@form_data.email}</strong>
                gesendet.
              </p>
              <div class="mt-4 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
                <p class="text-blue-800 dark:text-blue-300 text-sm">
                  <strong>Nächster Schritt:</strong>
                  Öffnen Sie Ihre E-Mails und klicken Sie auf den Link in der Nachricht.
                  Der Link ist 24 Stunden gültig.
                </p>
                <p class="text-blue-700 dark:text-blue-400 text-sm mt-2">
                  Keine E-Mail erhalten? Prüfen Sie auch Ihren Spam-Ordner.
                </p>
                <%= if @is_dev do %>
                  <div class="mt-3 pt-3 border-t border-blue-200 dark:border-blue-700">
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
            </div>
          </div>
        </div>
      <% else %>
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <!-- Form - Left Column -->
          <div class="lg:col-span-2">
            <div class="bg-white dark:bg-gray-800 shadow-sm border border-gray-200 dark:border-gray-700 rounded-lg p-6">
              <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100 mb-4">
                Schritt 1: Identität bestätigen
              </h2>
              <p class="text-gray-600 dark:text-gray-400 mb-6">
                Geben Sie Ihren Namen und Ihre E-Mail-Adresse ein. Wir senden Ihnen dann eine E-Mail mit einem Link zur Bestätigung.
              </p>

              <.form for={%{}} phx-change="validate" phx-submit="submit" class="space-y-4">
                <div>
                  <label
                    for="form_full_name"
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                  >
                    Vollständiger Name *
                  </label>
                  <input
                    type="text"
                    name="form[full_name]"
                    id="form_full_name"
                    value={@form_data.full_name}
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
                    for="form_email"
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                  >
                    E-Mail-Adresse *
                  </label>
                  <input
                    type="email"
                    name="form[email]"
                    id="form_email"
                    value={@form_data.email}
                    required
                    class={"mt-1 block w-full rounded-md border-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500 #{if @errors[:email], do: "border-red-500", else: "border-gray-300 dark:border-gray-600"}"}
                    placeholder="z.B. sekretariat@schule.de"
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
                    Um Ihre Anfrage zu bearbeiten, speichern wir folgende Daten:
                  </p>
                  <ul class="text-sm text-amber-700 dark:text-amber-300 mt-2 space-y-1">
                    <li>• Ihren Namen</li>
                    <li>• Ihre E-Mail-Adresse</li>
                    <li>• Die zu sperrenden Daten</li>
                  </ul>
                </div>

                <div class="pt-4">
                  <button
                    type="submit"
                    class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-white dark:focus:ring-offset-gray-800 focus:ring-blue-500"
                  >
                    E-Mail zur Bestätigung senden
                  </button>
                </div>
              </.form>
            </div>
          </div>
          
    <!-- Sidebar - Right Column -->
          <div class="space-y-6">
            <!-- Info Box -->
            <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
              <h3 class="text-sm font-semibold text-blue-900 dark:text-blue-100 mb-2">
                Was ist die Datensperrliste?
              </h3>
              <p class="text-sm text-blue-700 dark:text-blue-300">
                Schulen können beantragen, dass bestimmte Kontaktdaten (Telefonnummer, E-Mail, Homepage, etc.)
                nicht auf unserer Website angezeigt werden.
              </p>
            </div>
            
    <!-- How it works -->
            <div class="bg-white dark:bg-gray-800 shadow-sm border border-gray-200 dark:border-gray-700 rounded-lg p-4">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-gray-100 mb-3">
                So funktioniert's:
              </h3>
              <ol class="text-sm text-gray-600 dark:text-gray-400 space-y-3">
                <li class="flex items-start">
                  <span class="flex-shrink-0 w-6 h-6 bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-full flex items-center justify-center text-xs font-bold mr-2">
                    1
                  </span>
                  <span>Name und E-Mail eingeben</span>
                </li>
                <li class="flex items-start">
                  <span class="flex-shrink-0 w-6 h-6 bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-full flex items-center justify-center text-xs font-bold mr-2">
                    2
                  </span>
                  <span>Link in der E-Mail anklicken</span>
                </li>
                <li class="flex items-start">
                  <span class="flex-shrink-0 w-6 h-6 bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-full flex items-center justify-center text-xs font-bold mr-2">
                    3
                  </span>
                  <span>Zu sperrende Daten eingeben</span>
                </li>
              </ol>
            </div>
            
    <!-- Hints -->
            <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4">
              <h3 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Hinweise:</h3>
              <ul class="text-sm text-gray-500 dark:text-gray-400 space-y-1">
                <li>• Der Link ist 24 Stunden gültig</li>
                <li>• Max. 3 Anfragen pro Stunde</li>
                <li>• Platzhalter (* und ?) werden unterstützt</li>
              </ul>
            </div>

            <%= if @is_dev do %>
              <!-- Dev Mailbox Link -->
              <div class="bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800 rounded-lg p-4">
                <h3 class="text-sm font-semibold text-purple-900 dark:text-purple-100 mb-2">
                  Development
                </h3>
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
        </div>
      <% end %>
      
    <!-- Back Link -->
      <div class="mt-8 text-center">
        <Phoenix.Component.link
          navigate={~p"/wiki"}
          class="inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
        >
          <svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M10 19l-7-7m0 0l7-7m-7 7h18"
            />
          </svg>
          Zurück zum Wiki
        </Phoenix.Component.link>
      </div>
    </div>
    """
  end
end
