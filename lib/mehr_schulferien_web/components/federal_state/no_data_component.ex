defmodule MehrSchulferienWeb.FederalState.NoDataComponent do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  attr :conn, :map, required: true
  attr :country, :map, required: true
  attr :federal_state, :map, required: true
  attr :year, :integer, required: true
  attr :years_with_data, :list, required: true

  def no_data(assigns) do
    ~H"""
    <div class="bg-yellow-100 border-l-4 border-yellow-500 text-yellow-700 p-4 mb-4" role="alert">
      <p class="font-bold">Information</p>
      <p>Für das Jahr {@year} liegen keine Feriendaten vor.</p>
      <%= if length(@years_with_data) > 0 do %>
        <p class="mt-2">
          Bitte wählen Sie eines der verfügbaren Jahre:
          <%= for available_year <- @years_with_data do %>
            <.link
              navigate={
                ~p"/ferien/#{@country.slug}/bundesland/#{@federal_state.slug}/#{available_year}"
              }
              class="text-blue-600 hover:underline"
            >
              {available_year}
            </.link>
            {if available_year != List.last(@years_with_data), do: ", ", else: ""}
          <% end %>
        </p>
      <% end %>
    </div>
    """
  end
end
