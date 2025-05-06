defmodule MehrSchulferienWeb.FederalState.NoDataComponent do
  use Phoenix.Component

  import Phoenix.HTML.Link
  alias MehrSchulferienWeb.Router.Helpers, as: Routes

  attr :conn, :map, required: true
  attr :country, :map, required: true
  attr :federal_state, :map, required: true
  attr :year, :integer, required: true
  attr :years_with_data, :list, required: true

  def no_data(assigns) do
    ~H"""
    <div class="bg-yellow-100 border-l-4 border-yellow-500 text-yellow-700 p-4 mb-4" role="alert">
      <p class="font-bold">Information</p>
      <p>Für das Jahr <%= @year %> liegen keine Feriendaten vor.</p>
      <%= if length(@years_with_data) > 0 do %>
        <p class="mt-2">
          Bitte wählen Sie eines der verfügbaren Jahre:
          <%= for available_year <- @years_with_data do %>
            <%= link("#{available_year}",
              to:
                Routes.federal_state_path(
                  @conn,
                  :show_year,
                  @country.slug,
                  @federal_state.slug,
                  available_year
                ),
              class: "text-blue-600 hover:underline"
            ) %><%= if available_year != List.last(@years_with_data), do: ", ", else: "" %>
          <% end %>
        </p>
      <% end %>
    </div>
    """
  end
end
