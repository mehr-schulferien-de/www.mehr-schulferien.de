defmodule MehrSchulferienWeb.WikiHubLive do
  use MehrSchulferienWeb, :live_view

  on_mount {MehrSchulferienWeb.WikiAuth, :require_auth}

  alias MehrSchulferien.Config

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Wiki - Gemeinsam mehr Schulferien")
      |> assign(:daily_limit, Config.daily_change_limit())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <!-- Header Section -->
      <div class="text-center mb-12">
        <h1 class="text-4xl font-bold text-gray-900 dark:text-gray-100">
          Wiki - Gemeinsam mehr Schulferien
        </h1>
        <p class="mt-4 text-lg text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
          Helfen Sie mit, die Daten zu verbessern und aktuell zu halten
        </p>
      </div>
      
    <!-- Action Cards Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-12">
        <!-- Schools Card -->
        <div class="group relative bg-white dark:bg-gray-800 rounded-xl shadow-sm hover:shadow-lg transition-all duration-200 overflow-hidden">
          <!-- Colored top border -->
          <div class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-blue-500 to-blue-600">
          </div>

          <div class="p-8">
            <!-- Icon and Title -->
            <div class="flex items-center mb-4">
              <div class="flex-shrink-0 w-12 h-12 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-6 h-6 text-blue-600 dark:text-blue-400"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M12 21v-8.25M15.75 21v-8.25M8.25 21v-8.25M3 9l9-6 9 6m-1.5 12V10.332A48.36 48.36 0 0012 9.75c-2.551 0-5.056.2-7.5.582V21M3 21h18M12 6.75h.008v.008H12V6.75z"
                  />
                </svg>
              </div>
              <h2 class="ml-4 text-xl font-semibold text-gray-900 dark:text-gray-100">
                Schulen verwalten
              </h2>
            </div>
            
    <!-- Description -->
            <p class="text-gray-600 dark:text-gray-400 mb-6">
              Schuladressen hinzufügen, bearbeiten und aktualisieren
            </p>
            
    <!-- Action Buttons -->
            <div class="space-y-3">
              <Phoenix.Component.link
                navigate={~p"/wiki/schools/new"}
                class="block w-full text-center px-4 py-3 bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300 rounded-lg hover:bg-blue-100 dark:hover:bg-blue-900/30 transition-colors duration-150 font-medium"
              >
                <svg
                  class="inline-block w-4 h-4 mr-2"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                Neue Schule hinzufügen
              </Phoenix.Component.link>

              <Phoenix.Component.link
                href="/briefe"
                class="block w-full text-center px-4 py-3 bg-gray-50 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors duration-150 font-medium"
              >
                <svg
                  class="inline-block w-4 h-4 mr-2"
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
                Schulen suchen & bearbeiten
              </Phoenix.Component.link>
            </div>
          </div>
        </div>
        
    <!-- Vacation Periods Card -->
        <div class="group relative bg-white dark:bg-gray-800 rounded-xl shadow-sm hover:shadow-lg transition-all duration-200 overflow-hidden">
          <!-- Colored top border -->
          <div class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-green-500 to-green-600">
          </div>

          <div class="p-8">
            <!-- Icon and Title -->
            <div class="flex items-center mb-4">
              <div class="flex-shrink-0 w-12 h-12 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-6 h-6 text-green-600 dark:text-green-400"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5"
                  />
                </svg>
              </div>
              <h2 class="ml-4 text-xl font-semibold text-gray-900 dark:text-gray-100">
                Ferientermine verwalten
              </h2>
            </div>
            
    <!-- Description -->
            <p class="text-gray-600 dark:text-gray-400 mb-6">
              Schulferien für Bundesländer bearbeiten und korrigieren
            </p>
            
    <!-- Action Buttons -->
            <div class="space-y-3">
              <Phoenix.Component.link
                navigate={~p"/wiki/periods"}
                class="block w-full text-center px-4 py-3 bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-300 rounded-lg hover:bg-green-100 dark:hover:bg-green-900/30 transition-colors duration-150 font-medium"
              >
                <svg
                  class="inline-block w-4 h-4 mr-2"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                  />
                </svg>
                Ferientermine anzeigen & bearbeiten
              </Phoenix.Component.link>

              <Phoenix.Component.link
                navigate={~p"/wiki/periods/new"}
                class="block w-full text-center px-4 py-3 bg-gray-50 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors duration-150 font-medium"
              >
                <svg
                  class="inline-block w-4 h-4 mr-2"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                Neue Ferien hinzufügen
              </Phoenix.Component.link>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Guidelines Section -->
      <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-xl p-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4 flex items-center">
          <svg
            class="w-5 h-5 mr-2 text-blue-600 dark:text-blue-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          Richtlinien für Wiki-Beiträge
        </h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-3 text-sm">
          <div class="flex items-start">
            <svg
              class="w-4 h-4 mr-2 mt-0.5 text-blue-500 dark:text-blue-400 flex-shrink-0"
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
            <span class="text-gray-700 dark:text-gray-300">
              Alle Änderungen werden protokolliert und können rückgängig gemacht werden
            </span>
          </div>
          <div class="flex items-start">
            <svg
              class="w-4 h-4 mr-2 mt-0.5 text-blue-500 dark:text-blue-400 flex-shrink-0"
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
            <span class="text-gray-700 dark:text-gray-300">
              Bei jeder Änderung wird eine E-Mail-Benachrichtigung versendet
            </span>
          </div>
          <div class="flex items-start">
            <svg
              class="w-4 h-4 mr-2 mt-0.5 text-blue-500 dark:text-blue-400 flex-shrink-0"
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
            <span class="text-gray-700 dark:text-gray-300">
              Pro Tag sind maximal {@daily_limit} Änderungen erlaubt
            </span>
          </div>
          <div class="flex items-start">
            <svg
              class="w-4 h-4 mr-2 mt-0.5 text-blue-500 dark:text-blue-400 flex-shrink-0"
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
            <span class="text-gray-700 dark:text-gray-300">
              Bitte nur korrekte und verifizierte Informationen eintragen
            </span>
          </div>
        </div>
        <div class="mt-4 pt-4 border-t border-blue-200 dark:border-blue-800">
          <p class="text-sm text-gray-600 dark:text-gray-400">
            Bei Fragen oder Problemen wenden Sie sich bitte an den Support.
          </p>
        </div>
      </div>
    </div>
    """
  end
end
