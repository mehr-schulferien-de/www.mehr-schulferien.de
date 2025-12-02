defmodule MehrSchulferienWeb.FederalState.PeriodsTableComponent do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  import MehrSchulferienWeb.Shared.PeriodsTableBaseComponent

  attr :periods, :list, required: true
  attr :all_periods, :list, required: true
  attr :today, :any, default: Date.utc_today()
  attr :federal_state, :any, default: nil
  attr :conn, :any, default: nil
  attr :year, :integer, default: nil
  attr :current_year, :integer, default: nil

  def periods_table(assigns) do
    ~H"""
    <div
      class="overflow-x-auto"
      itemscope
      itemtype="https://schema.org/Table"
      tabindex="0"
      role="region"
      aria-label="Ferientermine Tabelle"
    >
      <meta itemprop="about" content={table_about_content(assigns)} />
      <table class="min-w-full bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <%= if assigns[:federal_state] && assigns[:year] do %>
          <caption class="sr-only">
            Ferientermine {assigns.federal_state.name} {assigns.year} - Übersicht aller Schulferien mit Datum und Dauer
          </caption>
        <% end %>
        <thead>
          <tr>
            <th class="px-2 sm:px-4 py-2 sm:py-3 bg-gray-50 dark:bg-gray-900 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider border-b dark:border-gray-600">
              Name
            </th>
            <th class="px-2 sm:px-4 py-2 sm:py-3 bg-gray-50 dark:bg-gray-900 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider border-b dark:border-gray-600">
              Termin
            </th>
            <th class="px-2 sm:px-4 py-2 sm:py-3 bg-gray-50 dark:bg-gray-900 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider border-b dark:border-gray-600">
              Tage*
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
          <%= for period <- @periods do %>
            <.period_row
              period={period}
              all_periods={@all_periods}
              today={@today}
              current_year={@current_year}
              period_link_builder={
                if @federal_state && @conn && vacation_type_slug(period) do
                  fn p -> vacation_url(@conn, p, @federal_state) end
                else
                  nil
                end
              }
            />
          <% end %>
        </tbody>
      </table>

      <.periods_footnote periods={@periods} all_periods={@all_periods} />
    </div>
    """
  end

  # Helper function to get vacation type slug
  defp vacation_type_slug(period) do
    case period.holiday_or_vacation_type.name do
      "Sommerferien" -> "sommerferien"
      "Osterferien" -> "osterferien"
      "Herbstferien" -> "herbstferien"
      "Weihnachtsferien" -> "weihnachtsferien"
      "Winterferien" -> "winterferien"
      "Pfingstferien" -> "pfingstferien"
      _ -> nil
    end
  end

  # Helper function to build vacation URL
  defp vacation_url(_conn, period, federal_state) do
    case vacation_type_slug(period) do
      nil ->
        nil

      slug ->
        ~p"/#{slug}/#{federal_state.slug}/#{period.starts_on.year}"
    end
  end

  defp table_about_content(assigns) do
    parts = ["Schulferien"]
    parts = if assigns[:federal_state], do: parts ++ [assigns.federal_state.name], else: parts
    parts = if assigns[:year], do: parts ++ [assigns.year], else: parts
    Enum.join(parts, " ")
  end
end
