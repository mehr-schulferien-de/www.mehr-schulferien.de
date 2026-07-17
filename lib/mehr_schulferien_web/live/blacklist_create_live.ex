defmodule MehrSchulferienWeb.BlacklistCreateLive do
  @moduledoc """
  LiveView for creating blacklist entries.

  Users arrive here after verifying their email. They can enter patterns
  to be blacklisted with a live preview of what will be affected.
  """
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.{Blacklist, Email, Mailer}
  alias MehrSchulferien.Blacklist.{Entry, PatternMatcher}
  alias MehrSchulferien.Helpers.PhoneFormatter

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    verification_request = Blacklist.get_verification_request_by_token(token)

    cond do
      is_nil(verification_request) ->
        {:ok,
         socket
         |> assign(page_title: "Ungültiger Link", status: :invalid)
         |> put_flash(:error, "Dieser Link ist ungültig.")}

      not Blacklist.valid_for_entry_creation?(verification_request) ->
        {:ok,
         socket
         |> assign(page_title: "Link abgelaufen", status: :expired)
         |> put_flash(:error, "Dieser Link ist abgelaufen.")}

      true ->
        {:ok,
         socket
         |> assign(
           page_title: "Blacklist-Eintrag erstellen",
           status: :valid,
           verification_request: verification_request,
           token: token,
           form_data: %{field_type: "phone_number", pattern: "", reason: ""},
           errors: %{},
           preview: nil,
           submitted: false,
           show_confirmation: false
         )}
    end
  end

  @impl true
  def handle_event("validate", %{"form" => form_params}, socket) do
    field_type = Map.get(form_params, "field_type", "phone_number")
    raw_pattern = Map.get(form_params, "pattern", "")

    # Auto-format phone/fax numbers after 6 characters to international format
    pattern = maybe_format_phone_number(raw_pattern, field_type)

    form_data = %{
      field_type: field_type,
      pattern: pattern,
      reason: Map.get(form_params, "reason", "")
    }

    # Generate preview when pattern has at least 4 characters (minimum required)
    preview =
      if String.length(String.trim(form_data.pattern)) >= 4 do
        generate_preview(form_data.pattern, form_data.field_type)
      else
        nil
      end

    socket = assign(socket, form_data: form_data, errors: %{}, preview: preview)

    # Push formatted value to JS hook if pattern was changed
    socket =
      if pattern != raw_pattern do
        push_event(socket, "format_phone", %{formatted: pattern})
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("show_confirmation", _params, socket) do
    {:noreply, assign(socket, show_confirmation: true)}
  end

  @impl true
  def handle_event("cancel_confirmation", _params, socket) do
    {:noreply, assign(socket, show_confirmation: false)}
  end

  @impl true
  def handle_event("confirm_submit", _params, socket) do
    form_data = socket.assigns.form_data
    field_type = form_data.field_type
    pattern = String.trim(form_data.pattern)
    reason = String.trim(form_data.reason)

    # Validate pattern
    case PatternMatcher.validate_pattern(pattern) do
      :ok ->
        # Create the blacklist entry
        attrs = %{
          field_type: field_type,
          pattern: pattern,
          reason: if(reason == "", do: nil, else: reason)
        }

        case Blacklist.create_entry(attrs, socket.assigns.verification_request) do
          {:ok, {entry, removal_logs}} ->
            removal_count = length(removal_logs)

            # Send admin notification
            Email.blacklist_entry_created_notification(entry, removal_count)
            |> Mailer.deliver()

            {:noreply,
             socket
             |> assign(
               submitted: true,
               entry: entry,
               removal_count: removal_count,
               show_confirmation: false
             )
             |> put_flash(:info, "Blacklist-Eintrag wurde erfolgreich erstellt.")}

          {:error, changeset} ->
            errors = format_changeset_errors(changeset)
            {:noreply, assign(socket, errors: errors, show_confirmation: false)}
        end

      {:error, message} ->
        {:noreply, assign(socket, errors: %{pattern: message}, show_confirmation: false)}
    end
  end

  @max_allowed_matches 4

  defp generate_preview(pattern, field_type) do
    case PatternMatcher.validate_pattern(pattern) do
      :ok ->
        count = Blacklist.count_matching_addresses(pattern, field_type)
        samples = Blacklist.sample_matching_addresses(pattern, field_type, 5)

        regex_pattern = PatternMatcher.to_regex_pattern(pattern)

        # Check if pattern is too broad (more than 4 matches)
        if count > @max_allowed_matches do
          %{
            count: count,
            samples: samples,
            regex_pattern: regex_pattern,
            valid: true,
            too_broad: true
          }
        else
          %{
            count: count,
            samples: samples,
            regex_pattern: regex_pattern,
            valid: true,
            too_broad: false
          }
        end

      {:error, message} ->
        %{
          valid: false,
          error: message
        }
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.into(%{}, fn {k, v} -> {k, Enum.join(v, ", ")} end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-6">
      <%= case @status do %>
        <% :valid -> %>
          <%= if @submitted do %>
            <!-- Success State -->
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
                    Daten wurden gesperrt
                  </h2>
                  <p class="text-gray-600 dark:text-gray-400 mt-2">
                    Die Sperrung wurde erfolgreich eingerichtet.
                  </p>
                  <div class="mt-4 bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                    <dl class="space-y-2 text-sm">
                      <div class="flex">
                        <dt class="font-medium text-gray-700 dark:text-gray-300 w-32">Gesperrt:</dt>
                        <dd class="text-gray-900 dark:text-gray-100">
                          <code class="bg-gray-200 dark:bg-gray-600 px-2 py-0.5 rounded">
                            {@entry.pattern}
                          </code>
                        </dd>
                      </div>
                      <div class="flex">
                        <dt class="font-medium text-gray-700 dark:text-gray-300 w-32">Datentyp:</dt>
                        <dd class="text-gray-900 dark:text-gray-100">
                          {Entry.field_type_labels()[@entry.field_type]}
                        </dd>
                      </div>
                      <div class="flex">
                        <dt class="font-medium text-gray-700 dark:text-gray-300 w-32">
                          Entfernt aus:
                        </dt>
                        <dd class="text-gray-900 dark:text-gray-100">{@removal_count} Schulen</dd>
                      </div>
                    </dl>
                  </div>
                  <div class="mt-4 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
                    <p class="text-blue-800 dark:text-blue-300 text-sm">
                      Die gesperrten Daten wurden aus allen betroffenen Schulen entfernt und können künftig nicht mehr eingegeben werden.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          <% else %>
            <!-- Header -->
            <div class="mb-8">
              <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-2">
                Daten sperren
              </h1>
              <p class="text-gray-600 dark:text-gray-400">
                Legen Sie fest, welche Kontaktdaten nicht mehr angezeigt werden sollen.
              </p>
            </div>
            
    <!-- Verified User Info -->
            <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4 mb-6">
              <div class="flex items-center">
                <svg
                  class="w-5 h-5 text-green-600 dark:text-green-400 mr-2"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                <p class="text-green-800 dark:text-green-300 text-sm">
                  <strong>Verifiziert als:</strong> {@verification_request.full_name} ({@verification_request.email})
                </p>
              </div>
            </div>

            <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
              <!-- Form - Left Column -->
              <div class="lg:col-span-2">
                <div class="bg-white dark:bg-gray-800 shadow-sm border border-gray-200 dark:border-gray-700 rounded-lg p-6">
                  <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100 mb-6">
                    Welche Daten sollen gesperrt werden?
                  </h2>

                  <.form for={%{}} phx-change="validate" class="space-y-6">
                    <!-- Field Type Selection -->
                    <div>
                      <label
                        for="form_field_type"
                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                      >
                        Art der Daten *
                      </label>
                      <div class="relative">
                        <select
                          name="form[field_type]"
                          id="form_field_type"
                          class={DesignTokens.form_select()}
                        >
                          <%= for {value, label} <- Entry.field_type_labels() do %>
                            <option value={value} selected={@form_data.field_type == value}>
                              {label}
                            </option>
                          <% end %>
                        </select>
                        <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-3 text-gray-500 dark:text-gray-400">
                          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M19 9l-7 7-7-7"
                            />
                          </svg>
                        </div>
                      </div>
                    </div>
                    
    <!-- Pattern Input -->
                    <div>
                      <label
                        for="form_pattern"
                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                      >
                        Zu sperrende Daten *
                      </label>
                      <input
                        type="text"
                        name="form[pattern]"
                        id="form_pattern"
                        value={@form_data.pattern}
                        required
                        autofocus
                        phx-debounce="300"
                        phx-hook="PhoneFormatter"
                        class={"mt-1 block w-full rounded-md border-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500 #{if @errors[:pattern], do: "border-red-500", else: "border-gray-300 dark:border-gray-600"}"}
                        placeholder={placeholder_for_field_type(@form_data.field_type)}
                      />
                      <%= if @errors[:pattern] do %>
                        <p class="mt-1 text-sm text-red-600 dark:text-red-400">{@errors[:pattern]}</p>
                      <% end %>
                    </div>
                    
    <!-- Live Preview - Always visible section -->
                    <div class={"rounded-lg p-4 border-2 #{cond do
                      @preview && !@preview.valid -> "bg-red-50 dark:bg-red-900/20 border-red-300 dark:border-red-700"
                      @preview && @preview[:too_broad] -> "bg-red-50 dark:bg-red-900/20 border-red-300 dark:border-red-700"
                      @preview && @preview.count > 0 -> "bg-green-50 dark:bg-green-900/20 border-green-300 dark:border-green-700"
                      @preview -> "bg-blue-50 dark:bg-blue-900/20 border-blue-300 dark:border-blue-700"
                      true -> "bg-gray-50 dark:bg-gray-700 border-gray-200 dark:border-gray-600"
                    end}"}>
                      <div class="flex items-center mb-3">
                        <svg
                          class={"w-5 h-5 mr-2 #{cond do
                          @preview && !@preview.valid -> "text-red-500"
                          @preview && @preview[:too_broad] -> "text-red-500"
                          @preview && @preview.count > 0 -> "text-green-500"
                          @preview -> "text-blue-500"
                          true -> "text-gray-400"
                        end}"}
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                          />
                        </svg>
                        <h3 class="font-semibold text-gray-900 dark:text-gray-100">
                          Live-Suche
                        </h3>
                      </div>

                      <%= if @preview do %>
                        <%= if @preview.valid do %>
                          <div class="flex items-center mb-3">
                            <span class={"text-2xl font-bold mr-2 #{cond do
                              @preview[:too_broad] -> "text-red-600 dark:text-red-400"
                              @preview.count > 0 -> "text-green-600 dark:text-green-400"
                              true -> "text-blue-600 dark:text-blue-400"
                            end}"}>
                              {@preview.count}
                            </span>
                            <span class="text-gray-600 dark:text-gray-400">
                              <%= if @preview.count == 1 do %>
                                Eintrag gefunden
                              <% else %>
                                Einträge gefunden
                              <% end %>
                            </span>
                          </div>

                          <%= if @preview[:too_broad] do %>
                            <!-- Too broad pattern error -->
                            <div class="bg-red-100 dark:bg-red-900/40 rounded-lg p-4 mb-3">
                              <div class="flex">
                                <svg
                                  class="w-5 h-5 text-red-600 dark:text-red-400 flex-shrink-0 mt-0.5"
                                  fill="none"
                                  stroke="currentColor"
                                  viewBox="0 0 24 24"
                                >
                                  <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                                  />
                                </svg>
                                <div class="ml-3">
                                  <h4 class="text-sm font-semibold text-red-800 dark:text-red-200">
                                    Muster zu allgemein
                                  </h4>
                                  <p class="text-sm text-red-700 dark:text-red-300 mt-1">
                                    Dieses Muster betrifft mehr als 4 Einträge ({@preview.count} gefunden).
                                    Aus Sicherheitsgründen können so breite Sperren nicht automatisch erstellt werden.
                                  </p>
                                  <p class="text-sm text-red-700 dark:text-red-300 mt-2">
                                    <strong>Lösung:</strong>
                                    Bitte verwenden Sie ein spezifischeres Muster, oder wenden Sie sich per E-Mail an:
                                  </p>
                                  <a
                                    href="mailto:sw@wintermeyer-consulting.de?subject=Blacklist-Anfrage%20für%20breites%20Muster"
                                    class="inline-flex items-center mt-2 text-sm font-medium text-red-800 dark:text-red-200 hover:text-red-900 dark:hover:text-red-100 underline"
                                  >
                                    <svg
                                      class="w-4 h-4 mr-1"
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
                                    Stefan Wintermeyer &lt;sw@wintermeyer-consulting.de&gt;
                                  </a>
                                </div>
                              </div>
                            </div>
                          <% end %>

                          <%= if @preview.count > 0 do %>
                            <div class="bg-white dark:bg-gray-800 rounded-md border border-gray-200 dark:border-gray-600 divide-y divide-gray-200 dark:divide-gray-600">
                              <%= for sample <- @preview.samples do %>
                                <div class="p-3">
                                  <div class="text-sm font-medium text-gray-900 dark:text-gray-100 mb-1">
                                    <%= if sample.school_location do %>
                                      <a
                                        href={~p"/ferien/d/schule/#{sample.school_location.slug}"}
                                        target="_blank"
                                        class="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 hover:underline"
                                      >
                                        {sample.school_location.name}
                                        <svg
                                          class="inline-block w-3 h-3 ml-1"
                                          fill="none"
                                          stroke="currentColor"
                                          viewBox="0 0 24 24"
                                        >
                                          <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="2"
                                            d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                                          />
                                        </svg>
                                      </a>
                                    <% end %>
                                  </div>
                                  <code class="text-sm bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-200 px-2 py-1 rounded">
                                    {Map.get(sample, String.to_existing_atom(@form_data.field_type))}
                                  </code>
                                </div>
                              <% end %>
                            </div>
                            <%= if @preview.count > 5 do %>
                              <p class="mt-2 text-sm text-gray-500 dark:text-gray-400 italic">
                                ... und {@preview.count - 5} weitere Einträge
                              </p>
                            <% end %>
                          <% else %>
                            <p class="text-sm text-blue-700 dark:text-blue-300">
                              Keine Einträge in der Datenbank gefunden.
                              Das Muster wird trotzdem gesperrt für zukünftige Eingaben.
                            </p>
                          <% end %>
                        <% else %>
                          <p class="text-sm text-red-600 dark:text-red-400 font-medium">
                            {@preview.error}
                          </p>
                        <% end %>
                      <% else %>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                          Geben Sie oben die zu sperrenden Daten ein (mindestens 4 Zeichen), um passende Einträge zu finden.
                        </p>
                      <% end %>
                    </div>
                    
    <!-- Reason -->
                    <div>
                      <label
                        for="form_reason"
                        class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                      >
                        Begründung (optional)
                      </label>
                      <textarea
                        name="form[reason]"
                        id="form_reason"
                        rows="3"
                        class={DesignTokens.form_input()}
                        placeholder="z.B. Telefonnummer der Schule hat sich geändert"
                      >{@form_data.reason}</textarea>
                    </div>
                    
    <!-- Warning -->
                    <div class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-4">
                      <div class="flex">
                        <svg
                          class="w-5 h-5 text-amber-600 dark:text-amber-400 flex-shrink-0 mt-0.5"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                          />
                        </svg>
                        <div class="ml-3">
                          <p class="text-sm text-amber-700 dark:text-amber-300">
                            <strong>Achtung:</strong>
                            Diese Aktion kann nicht rückgängig gemacht werden.
                            Die Daten werden sofort aus allen Schulen entfernt.
                          </p>
                        </div>
                      </div>
                    </div>
                    
    <!-- Submit Button -->
                    <div class="pt-2">
                      <button
                        type="button"
                        phx-click="show_confirmation"
                        disabled={!@preview || !@preview.valid || @preview[:too_broad]}
                        class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-white dark:focus:ring-offset-gray-800 focus:ring-blue-500 disabled:bg-gray-400 disabled:cursor-not-allowed"
                      >
                        Daten jetzt sperren
                      </button>
                    </div>
                  </.form>
                </div>
              </div>
              
    <!-- Sidebar - Right Column -->
              <div class="space-y-6">
                <!-- Help Box -->
                <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
                  <h3 class="text-sm font-semibold text-blue-900 dark:text-blue-100 mb-2">
                    Wie funktioniert's?
                  </h3>
                  <ol class="text-sm text-blue-700 dark:text-blue-300 space-y-2">
                    <li class="flex items-start">
                      <span class="font-bold mr-2">1.</span>
                      <span>Wählen Sie die Art der Daten (z.B. Telefon, E-Mail)</span>
                    </li>
                    <li class="flex items-start">
                      <span class="font-bold mr-2">2.</span>
                      <span>Geben Sie die zu sperrenden Daten ein</span>
                    </li>
                    <li class="flex items-start">
                      <span class="font-bold mr-2">3.</span>
                      <span>Prüfen Sie die Vorschau</span>
                    </li>
                    <li class="flex items-start">
                      <span class="font-bold mr-2">4.</span>
                      <span>Klicken Sie auf "Daten jetzt sperren"</span>
                    </li>
                  </ol>
                </div>
                
    <!-- Wildcards Help -->
                <div class="bg-white dark:bg-gray-800 shadow-sm border border-gray-200 dark:border-gray-700 rounded-lg p-4">
                  <h3 class="text-sm font-semibold text-gray-900 dark:text-gray-100 mb-3">
                    Mehrere Einträge sperren
                  </h3>
                  <p class="text-sm text-gray-600 dark:text-gray-400 mb-3">
                    Mit Platzhaltern können Sie mehrere ähnliche Einträge gleichzeitig sperren:
                  </p>
                  <div class="space-y-2 text-sm">
                    <div class="bg-gray-50 dark:bg-gray-700 rounded p-2">
                      <code class="text-blue-600 dark:text-blue-400">*</code>
                      <span class="text-gray-600 dark:text-gray-400 ml-2">
                        = beliebig viele Zeichen
                      </span>
                    </div>
                    <div class="bg-gray-50 dark:bg-gray-700 rounded p-2">
                      <code class="text-blue-600 dark:text-blue-400">?</code>
                      <span class="text-gray-600 dark:text-gray-400 ml-2">= genau ein Zeichen</span>
                    </div>
                  </div>
                  <div class="mt-3 pt-3 border-t border-gray-200 dark:border-gray-600">
                    <p class="text-xs text-gray-500 dark:text-gray-400 mb-2">Beispiele:</p>
                    <ul class="text-xs text-gray-500 dark:text-gray-400 space-y-1">
                      <li>
                        <code class="bg-gray-100 dark:bg-gray-600 px-1 rounded">+49 30 123*</code>
                        → alle Nummern die so beginnen
                      </li>
                      <li>
                        <code class="bg-gray-100 dark:bg-gray-600 px-1 rounded">*@schule.de</code>
                        → alle E-Mails dieser Domain
                      </li>
                    </ul>
                  </div>
                </div>
                
    <!-- Data Types Info -->
                <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4">
                  <h3 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Sperrbare Daten:
                  </h3>
                  <ul class="text-sm text-gray-500 dark:text-gray-400 space-y-1">
                    <li>• Telefonnummer</li>
                    <li>• Faxnummer</li>
                    <li>• E-Mail-Adresse</li>
                    <li>• Homepage</li>
                    <li>• Social Media Links</li>
                  </ul>
                </div>
              </div>
            </div>
          <% end %>
        <% :invalid -> %>
          <!-- Invalid Token State -->
          <div class="max-w-lg mx-auto">
            <div class="bg-white dark:bg-gray-800 shadow-sm border border-gray-200 dark:border-gray-700 rounded-lg p-6 text-center">
              <div class="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-red-100 dark:bg-red-900/30 mb-6">
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
                  >
                  </path>
                </svg>
              </div>
              <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-4">
                Ungültiger Link
              </h1>
              <p class="text-gray-600 dark:text-gray-400 mb-8">
                Dieser Link ist ungültig. Bitte fordern Sie einen neuen Bestätigungslink an.
              </p>
              <Phoenix.Component.link
                navigate={~p"/wiki/blacklist/request"}
                class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                Neuen Link anfordern
              </Phoenix.Component.link>
            </div>
          </div>
        <% :expired -> %>
          <!-- Expired Token State -->
          <div class="max-w-lg mx-auto">
            <div class="bg-white dark:bg-gray-800 shadow-sm border border-gray-200 dark:border-gray-700 rounded-lg p-6 text-center">
              <div class="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-yellow-100 dark:bg-yellow-900/30 mb-6">
                <svg
                  class="h-8 w-8 text-yellow-600 dark:text-yellow-400"
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
              <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-4">
                Link abgelaufen
              </h1>
              <p class="text-gray-600 dark:text-gray-400 mb-8">
                Dieser Link ist abgelaufen. Bitte fordern Sie einen neuen Bestätigungslink an.
              </p>
              <Phoenix.Component.link
                navigate={~p"/wiki/blacklist/request"}
                class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                Neuen Link anfordern
              </Phoenix.Component.link>
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

    <!-- Confirmation Modal -->
    <%= if @show_confirmation do %>
      <div
        class="fixed z-50 inset-0 overflow-y-auto"
        aria-labelledby="confirmation-modal-title"
        role="dialog"
        aria-modal="true"
      >
        <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
          <!-- Background overlay -->
          <div
            class="fixed inset-0 bg-gray-500 dark:bg-gray-800 bg-opacity-75 dark:bg-opacity-75 transition-opacity"
            aria-hidden="true"
            phx-click="cancel_confirmation"
          >
          </div>
          
    <!-- Modal centering trick -->
          <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">
            &#8203;
          </span>
          
    <!-- Modal panel -->
          <div class="inline-block align-bottom bg-white dark:bg-gray-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
            <div class="bg-white dark:bg-gray-800 px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
              <div class="sm:flex sm:items-start">
                <div class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-red-100 dark:bg-red-900/30 sm:mx-0 sm:h-10 sm:w-10">
                  <svg
                    class="h-6 w-6 text-red-600 dark:text-red-400"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                    >
                    </path>
                  </svg>
                </div>
                <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left flex-grow">
                  <h3
                    class="text-lg leading-6 font-medium text-gray-900 dark:text-gray-100"
                    id="confirmation-modal-title"
                  >
                    Sind Sie sicher?
                  </h3>
                  <div class="mt-4 space-y-3">
                    <p class="text-sm text-gray-600 dark:text-gray-400">
                      Sie sind dabei, folgende Daten auf die <strong>Blacklist</strong>
                      zu setzen (dauerhaft zu sperren):
                    </p>
                    <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-3">
                      <dl class="space-y-2 text-sm">
                        <div class="flex">
                          <dt class="font-medium text-gray-700 dark:text-gray-300 w-24">Muster:</dt>
                          <dd class="text-gray-900 dark:text-gray-100">
                            <code class="bg-gray-200 dark:bg-gray-600 px-2 py-0.5 rounded">
                              {@form_data.pattern}
                            </code>
                          </dd>
                        </div>
                        <div class="flex">
                          <dt class="font-medium text-gray-700 dark:text-gray-300 w-24">Datentyp:</dt>
                          <dd class="text-gray-900 dark:text-gray-100">
                            {Entry.field_type_labels()[@form_data.field_type]}
                          </dd>
                        </div>
                        <%= if @preview && @preview.count > 0 do %>
                          <div class="flex">
                            <dt class="font-medium text-gray-700 dark:text-gray-300 w-24">
                              Betroffen:
                            </dt>
                            <dd class="text-gray-900 dark:text-gray-100">
                              {@preview.count} {if @preview.count == 1, do: "Schule", else: "Schulen"}
                            </dd>
                          </div>
                        <% end %>
                      </dl>
                    </div>
                    <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3">
                      <p class="text-sm text-red-700 dark:text-red-300">
                        <strong>Warnung:</strong> Diese Aktion kann nicht rückgängig gemacht werden!
                      </p>
                      <ul class="mt-2 text-sm text-red-600 dark:text-red-400 list-disc ml-5 space-y-1">
                        <li>Die Daten werden sofort aus allen betroffenen Schulen entfernt</li>
                        <li>Das Muster wird dauerhaft gesperrt</li>
                        <li>Zukünftige Eingaben dieses Musters werden blockiert</li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="bg-gray-50 dark:bg-gray-700 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
              <button
                type="button"
                phx-click="confirm_submit"
                class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 dark:bg-red-500 text-base font-medium text-white hover:bg-red-700 dark:hover:bg-red-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm"
              >
                Ja, Daten jetzt sperren
              </button>
              <button
                type="button"
                phx-click="cancel_confirmation"
                class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 dark:border-gray-600 shadow-sm px-4 py-2 bg-white dark:bg-gray-800 text-base font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
              >
                Abbrechen
              </button>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  # Auto-format phone/fax numbers to international format after 6 characters
  # Converts "030 1234" to "+49 30 1234" for German numbers
  defp maybe_format_phone_number(pattern, field_type)
       when field_type in ["phone_number", "fax_number"] do
    trimmed = String.trim(pattern)

    # Only format if pattern is at least 6 characters and doesn't already start with +
    if String.length(trimmed) >= 6 and not String.starts_with?(trimmed, "+") do
      # Extract any trailing wildcards (* or ?)
      {base_pattern, wildcards} = extract_wildcards(trimmed)

      # Try to format the base pattern
      formatted = PhoneFormatter.format_international(base_pattern)

      # If formatting succeeded (changed the pattern), use it; otherwise keep original
      if formatted != base_pattern and String.starts_with?(formatted, "+") do
        formatted <> wildcards
      else
        pattern
      end
    else
      pattern
    end
  end

  defp maybe_format_phone_number(pattern, _field_type), do: pattern

  # Extract trailing wildcards from a pattern
  defp extract_wildcards(pattern) do
    case Regex.run(~r/^(.+?)([*?]+)$/, pattern) do
      [_, base, wildcards] -> {base, wildcards}
      _ -> {pattern, ""}
    end
  end

  defp placeholder_for_field_type("phone_number"), do: "+49 30 1234*"
  defp placeholder_for_field_type("fax_number"), do: "+49 30 1234*"
  defp placeholder_for_field_type("email_address"), do: "info@*.schule.de"
  defp placeholder_for_field_type("homepage_url"), do: "https://*.schule.de"
  defp placeholder_for_field_type("instagram_url"), do: "https://instagram.com/*"
  defp placeholder_for_field_type("wikipedia_url"), do: "https://de.wikipedia.org/*"
  defp placeholder_for_field_type("schuelerzeitung_url"), do: "https://*.schuelerzeitung.de"
  defp placeholder_for_field_type(_), do: "Muster eingeben..."
end
