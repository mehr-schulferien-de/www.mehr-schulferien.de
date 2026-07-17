defmodule MehrSchulferienWeb.DeveloperSectionComponent do
  @moduledoc """
  Renders the "Für Entwickler" section shown on city, federal state and
  school pages: a WordPress plugin card, an API access card and the
  GitHub open source promotion.
  """
  use Phoenix.Component

  import MehrSchulferienWeb.Shared.CardComponent
  import MehrSchulferienWeb.Shared.TypographyComponent

  @doc """
  Renders the developer section for a location.

  ## Examples

      <.developer_section location_name={@city.name} location_slug={@city.slug} location_type="city" />
  """
  attr :location_name, :string, required: true
  attr :location_slug, :string, required: true

  attr :location_type, :string,
    required: true,
    values: ["city", "federal_state", "school"],
    doc: "Used for the WordPress shortcode and to derive the API path segment"

  def developer_section(assigns) do
    assigns = assign(assigns, :api_path_segment, api_path_segment(assigns.location_type))

    ~H"""
    <div class="mt-12 border-t border-gray-200 dark:border-gray-700">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <.heading level={2} class="text-2xl text-center mb-8">
          Für Entwickler
        </.heading>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
          <!-- WordPress Plugin Card -->
          <.card variant="enhanced" padding="p-6">
            <:content>
              <div class="flex items-start">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-8 w-8 text-blue-600 dark:text-blue-400 mr-4 flex-shrink-0"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"
                  />
                </svg>
                <div>
                  <.heading level={3} class="text-lg mb-2">
                    WordPress Plugin
                  </.heading>
                  <.text variant="small" class="text-gray-700 dark:text-gray-300 mb-4">
                    Integrieren Sie die Schulferien von {@location_name} direkt in Ihre WordPress-Website mit unserem kostenlosen Plugin.
                  </.text>

                  <div class="bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-md p-3 mb-4 font-mono text-xs break-all text-gray-900 dark:text-gray-100">
                    [schulferien location_type="{@location_type}" location="{@location_slug}" display="table"]
                  </div>

                  <a
                    href="https://github.com/mehr-schulferien-de/mehr-schulferien-wordpress-plugin"
                    class="inline-flex items-center text-sm font-medium text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-4 w-4 mr-1"
                      fill="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
                    </svg>
                    Plugin auf GitHub ansehen
                  </a>
                </div>
              </div>
            </:content>
          </.card>
          <!-- API Access Card -->
          <.card variant="enhanced" padding="p-6">
            <:content>
              <div class="flex items-start">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-8 w-8 text-green-600 dark:text-green-400 mr-4 flex-shrink-0"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                  />
                </svg>
                <div>
                  <.heading level={3} class="text-lg mb-2">
                    API Zugriff
                  </.heading>
                  <.text variant="small" class="text-gray-700 dark:text-gray-300 mb-4">
                    Nutzen Sie unsere REST API, um Feriendaten in Ihre eigenen Anwendungen zu integrieren.
                  </.text>

                  <div class="space-y-2">
                    <div class="bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-md p-3 font-mono text-xs break-all text-gray-900 dark:text-gray-100">
                      GET /api/v2.1/{@api_path_segment}/{@location_slug}/icalendar
                    </div>
                    <div class="bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-md p-3 font-mono text-xs break-all text-gray-900 dark:text-gray-100">
                      GET /api/v2.1/{@api_path_segment}/{@location_slug}/periods
                    </div>
                  </div>

                  <.text variant="muted" class="mt-3">
                    Die API liefert Daten im JSON- und iCal-Format.
                  </.text>
                </div>
              </div>
            </:content>
          </.card>
        </div>
        <!-- Open Source Contribution -->
        <div class="mt-8">
          <MehrSchulferienWeb.Components.GitHubPromotionComponent.github_promotion
            locale="de"
            wrapper_class="bg-gray-50 dark:bg-gray-800 rounded-lg px-6 py-8 sm:px-8"
          />
        </div>
      </div>
    </div>
    """
  end

  defp api_path_segment("city"), do: "cities"
  defp api_path_segment("federal_state"), do: "federal-states"
  defp api_path_segment("school"), do: "schools"
end
