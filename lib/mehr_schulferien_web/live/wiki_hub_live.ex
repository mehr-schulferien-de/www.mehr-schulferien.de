defmodule MehrSchulferienWeb.WikiHubLive do
  use MehrSchulferienWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Wiki - Gemeinsam mehr Schulferien")
      |> assign(:css_framework, :tailwind_new)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 dark:bg-gray-900 py-8">
      <.container>
        <.stack spacing="6">
          <div class="text-center">
            <.heading level={1} class="text-gray-900 dark:text-gray-100">
              Wiki - Gemeinsam mehr Schulferien
            </.heading>
            <.text class="mt-4 text-gray-600 dark:text-gray-400 text-lg">
              Helfen Sie mit, die Daten zu verbessern und aktuell zu halten
            </.text>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <.card variant="enhanced" class="dark:bg-gray-800">
              <:content>
                <div class="flex items-start gap-4">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="w-8 h-8 text-primary-600 dark:text-primary-400 flex-shrink-0"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M12 21v-8.25M15.75 21v-8.25M8.25 21v-8.25M3 9l9-6 9 6m-1.5 12V10.332A48.36 48.36 0 0012 9.75c-2.551 0-5.056.2-7.5.582V21M3 21h18M12 6.75h.008v.008H12V6.75z"
                    />
                  </svg>
                  <div class="flex-1">
                    <.heading level={3} class="text-gray-900 dark:text-gray-100">
                      Schulen verwalten
                    </.heading>
                    <.text class="mt-2 text-gray-600 dark:text-gray-400">
                      Schuladressen hinzufügen, bearbeiten und aktualisieren
                    </.text>
                    <.stack spacing="2" class="mt-4">
                      <Phoenix.Component.link
                        navigate={~p"/wiki/schools/new"}
                        class="text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-300"
                      >
                        → Neue Schule hinzufügen
                      </Phoenix.Component.link>
                      <Phoenix.Component.link
                        href="/"
                        class="text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-300"
                      >
                        → Nach Schulen suchen
                      </Phoenix.Component.link>
                    </.stack>
                  </div>
                </div>
              </:content>
            </.card>

            <.card variant="enhanced" class="dark:bg-gray-800">
              <:content>
                <div class="flex items-start gap-4">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="w-8 h-8 text-primary-600 dark:text-primary-400 flex-shrink-0"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5"
                    />
                  </svg>
                  <div class="flex-1">
                    <.heading level={3} class="text-gray-900 dark:text-gray-100">
                      Ferientermine verwalten
                    </.heading>
                    <.text class="mt-2 text-gray-600 dark:text-gray-400">
                      Schulferien für Bundesländer bearbeiten und korrigieren
                    </.text>
                    <.stack spacing="2" class="mt-4">
                      <Phoenix.Component.link
                        navigate={~p"/wiki/periods"}
                        class="text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-300"
                      >
                        → Ferientermine anzeigen
                      </Phoenix.Component.link>
                      <Phoenix.Component.link
                        navigate={~p"/wiki/periods/new"}
                        class="text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-300"
                      >
                        → Neue Ferien hinzufügen
                      </Phoenix.Component.link>
                    </.stack>
                  </div>
                </div>
              </:content>
            </.card>
          </div>

          <.card variant="border" class="mt-8 dark:bg-blue-900 dark:border-blue-700">
            <:content>
              <.heading level={4} class="text-gray-900 dark:text-gray-100">
                Richtlinien für Wiki-Beiträge
              </.heading>
              <ul class="mt-4 space-y-2 list-disc ml-5 text-gray-700 dark:text-gray-300">
                <li>Alle Änderungen werden protokolliert und können rückgängig gemacht werden</li>
                <li>Bei jeder Änderung wird eine E-Mail-Benachrichtigung versendet</li>
                <li>Pro Tag sind maximal 100 Änderungen erlaubt</li>
                <li>Bitte nur korrekte und verifizierte Informationen eintragen</li>
                <li>Bei Fragen oder Problemen wenden Sie sich an den Support</li>
              </ul>
            </:content>
          </.card>
        </.stack>
      </.container>
    </div>
    """
  end
end
