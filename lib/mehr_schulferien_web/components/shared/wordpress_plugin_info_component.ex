defmodule MehrSchulferienWeb.Shared.WordPressPluginInfoComponent do
  @moduledoc """
  Component for displaying WordPress plugin information on location pages.
  """
  use Phoenix.Component
  alias MehrSchulferienWeb.Shared.CardComponent
  alias MehrSchulferienWeb.Shared.TypographyComponent

  attr :location_type, :atom, required: true, values: [:federal_state, :city, :school]
  attr :location_name, :string, required: true
  attr :location_slug, :string, required: true

  def wordpress_plugin_info(assigns) do
    location_type_de =
      case assigns.location_type do
        :federal_state -> "Bundesland"
        :city -> "Stadt"
        :school -> "Schule"
      end

    assigns = assign(assigns, :location_type_de, location_type_de)

    ~H"""
    <div class="mt-6">
      <CardComponent.card variant="enhanced" padding="p-4">
        <:content>
          <TypographyComponent.heading level={3} class="text-lg mb-3 flex items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 mr-2 text-blue-600"
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
            WordPress Plugin
          </TypographyComponent.heading>

          <TypographyComponent.text variant="small" class="text-gray-700 mb-3">
            Zeigen Sie die Schulferien von {@location_name} auf Ihrer WordPress-Webseite an.
            Unser Plugin ermöglicht es Ihnen, aktuelle Ferientermine für {(@location_type_de ==
                                                                             "Schule" && "diese") ||
              "dieses"} {@location_type_de} mit einem einfachen Shortcode einzubinden.
          </TypographyComponent.text>

          <div class="bg-gray-50 border border-gray-200 rounded-md p-3 mb-3">
            <p class="text-xs font-mono text-gray-800">
              [schulferien location_type="{@location_type}" location="{@location_slug}" display="table"]
            </p>
          </div>

          <TypographyComponent.link
            href="https://github.com/mehr-schulferien-de/mehr-schulferien-wordpress-plugin"
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex items-center text-sm font-medium"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-4 w-4 mr-1"
              fill="currentColor"
              viewBox="0 0 24 24"
            >
              <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
            </svg>
            Mehr Informationen und Installation
          </TypographyComponent.link>
        </:content>
      </CardComponent.card>
    </div>
    """
  end
end
