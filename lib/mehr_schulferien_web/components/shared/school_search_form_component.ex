defmodule MehrSchulferienWeb.Shared.SchoolSearchFormComponent do
  use Phoenix.Component
  import MehrSchulferienWeb.Shared.ButtonComponent

  @doc """
  Renders a school search form.

  ## Options
    * `:federal_states` - List of federal states for the dropdown (optional)
    * `:show_federal_state` - Whether to show the federal state dropdown (default: true)
    * `:search_params` - Current search parameters
    * `:searching` - Whether a search is in progress
    * `:location_label` - Label for the location field (default: "Stadt oder PLZ")
    * `:location_placeholder` - Placeholder for the location field
    * `:autofocus_field` - Which field to autofocus (:federal_state, :location, :school_name)
  """
  attr :federal_states, :list, default: []
  attr :show_federal_state, :boolean, default: true
  attr :search_params, :map, required: true
  attr :searching, :boolean, default: false
  attr :location_label, :string, default: "Stadt oder PLZ"
  attr :location_placeholder, :string, default: "z.B. Berlin, 10115 oder *burg"
  attr :autofocus_field, :atom, default: nil
  slot :below_form

  def school_search_form(assigns) do
    ~H"""
    <form
      phx-submit="search"
      phx-change="validate"
      class="mb-6 sm:mb-8 bg-white dark:bg-gray-800 shadow-sm rounded-lg p-4 sm:p-6"
    >
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-6">
        <%= if @show_federal_state && length(@federal_states) > 0 do %>
          <div>
            <label
              for="search_federal_state"
              class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
            >
              Bundesland
            </label>
            <select
              name="search[federal_state_id]"
              id="search_federal_state"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 rounded-md focus:ring-blue-500 focus:border-blue-500 h-[42px]"
              phx-change="validate"
              value={@search_params["federal_state_id"] || ""}
              autofocus={@autofocus_field == :federal_state}
            >
              <option value="">Alle Bundesländer</option>
              <%= for {name, id} <- @federal_states do %>
                <option
                  value={to_string(id)}
                  selected={@search_params["federal_state_id"] == to_string(id)}
                >
                  {name}
                </option>
              <% end %>
            </select>
          </div>
        <% end %>
        <div>
          <label
            for="search_location"
            class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
          >
            {@location_label}
          </label>
          <input
            type="text"
            name={if @show_federal_state, do: "search[location]", else: "search[zip_code]"}
            value={get_location_value(@search_params, @show_federal_state)}
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 dark:placeholder-gray-400 rounded-md focus:ring-blue-500 focus:border-blue-500 h-[42px]"
            placeholder={@location_placeholder}
            id="search_location"
            phx-debounce="300"
            autofocus={
              @autofocus_field == :location || (!@show_federal_state && @autofocus_field == nil)
            }
          />
        </div>
        <%= if !@show_federal_state do %>
          <div>
            <label
              for="search_city"
              class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
            >
              Stadt
            </label>
            <input
              type="text"
              name="search[city]"
              value={@search_params["city"] || ""}
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 dark:placeholder-gray-400 rounded-md focus:ring-blue-500 focus:border-blue-500 h-[42px]"
              placeholder="z.B. Berlin"
              id="search_city"
              phx-debounce="300"
            />
          </div>
        <% end %>
        <div>
          <label
            for="search_school_name"
            class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
          >
            Schulname
          </label>
          <input
            type="text"
            name="search[school_name]"
            value={@search_params["school_name"] || ""}
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 dark:placeholder-gray-400 rounded-md focus:ring-blue-500 focus:border-blue-500 h-[42px]"
            placeholder="z.B. Gymnasium oder Real*"
            id="search_school_name"
            phx-debounce="300"
            autofocus={@autofocus_field == :school_name}
          />
        </div>
      </div>
      <div class="mt-6 flex gap-3">
        <.button type="submit" variant="primary" disabled={@searching}>
          {if @searching, do: "Suche läuft...", else: "Suchen"}
        </.button>
        <button
          type="button"
          phx-click="reset"
          class="inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 text-sm font-medium rounded-md text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 dark:focus:ring-indigo-400"
        >
          Zurücksetzen
        </button>
      </div>
      <div class="mt-3 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
        <%= if @search_params["location"] == "" and @search_params["school_name"] == "" do %>
          <div class="text-xs text-gray-600 dark:text-gray-400">
            <span class="inline-flex items-center gap-1">
              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              Tipp: Verwenden Sie * für erweiterte Suchen (z.B. *dorf findet alle Orte die auf "dorf" enden)
            </span>
          </div>
        <% else %>
          <div></div>
        <% end %>
        <a
          href="/wiki/schools/new"
          class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 underline inline-flex items-center gap-1"
        >
          <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          Schule nicht gefunden? Hier anlegen
        </a>
      </div>
      {render_slot(@below_form)}
    </form>
    """
  end

  defp get_location_value(search_params, true), do: search_params["location"] || ""
  defp get_location_value(search_params, false), do: search_params["zip_code"] || ""
end
