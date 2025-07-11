defmodule MehrSchulferienWeb.FederalState.PeriodsTableComponent do
  use Phoenix.Component

  alias MehrSchulferienWeb.ViewHelpers
  import MehrSchulferienWeb.FederalState.PeriodNameComponent

  attr :periods, :list, required: true
  attr :all_periods, :list, required: true
  attr :today, :any, default: Date.utc_today()
  attr :federal_state, :any, default: nil
  attr :conn, :any, default: nil
  attr :year, :integer, default: nil

  def periods_table(assigns) do
    ~H"""
    <div class="overflow-x-auto" itemscope itemtype="https://schema.org/Table">
      <meta itemprop="about" content={table_about_content(assigns)} />
      <table class="min-w-full bg-white border border-gray-200">
        <%= if assigns[:federal_state] && assigns[:year] do %>
          <caption class="sr-only">
            Ferientermine <%= assigns.federal_state.name %> <%= assigns.year %> - Übersicht aller Schulferien mit Datum und Dauer
          </caption>
        <% end %>
        <thead>
          <tr>
            <th class="px-2 sm:px-4 py-2 sm:py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider border-b">
              Name
            </th>
            <th class="px-2 sm:px-4 py-2 sm:py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider border-b">
              Termin
            </th>
            <th class="px-2 sm:px-4 py-2 sm:py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider border-b">
              Tage*
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-200">
          <%= for period <- @periods do %>
            <% is_current =
              Date.compare(@today, period.starts_on) != :lt &&
                Date.compare(@today, period.ends_on) != :gt %>
            <% is_past =
              Date.compare(@today, period.ends_on) == :gt && period.starts_on.year == @today.year %>
            <% month_name =
              case period.starts_on.month do
                1 -> "januar"
                2 -> "februar"
                3 -> "märz"
                4 -> "april"
                5 -> "mai"
                6 -> "juni"
                7 -> "juli"
                8 -> "august"
                9 -> "september"
                10 -> "oktober"
                11 -> "november"
                12 -> "dezember"
              end %>
            <tr
              class={"hover:bg-gray-50 cursor-pointer #{if is_current, do: "bg-yellow-100"} #{if is_past, do: "text-gray-400"}"}
              onclick={"window.location.href='##{month_name}#{period.starts_on.year}'"}
            >
              <td class="px-2 sm:px-4 py-2 sm:py-3 text-sm font-medium">
                <%= if @federal_state && @conn && vacation_type_slug(period) do %>
                  <a
                    href={vacation_url(@conn, period, @federal_state)}
                    class="text-blue-600 hover:text-blue-800 underline"
                  >
                    <.period_name period={period} />
                  </a>
                <% else %>
                  <.period_name period={period} />
                <% end %>
              </td>
              <td class="px-2 sm:px-4 py-2 sm:py-3 text-sm">
                <span class="whitespace-nowrap">
                  <%= if Date.compare(period.starts_on, period.ends_on) == :eq do %>
                    <span class="sm:hidden">
                      <%= Calendar.strftime(period.starts_on, "%d.%m.") %>
                    </span>
                    <span class="hidden sm:inline">
                      <%= Calendar.strftime(period.starts_on, "%d.%m.%Y") %>
                    </span>
                  <% else %>
                    <span class="sm:hidden">
                      <%= Calendar.strftime(period.starts_on, "%d.%m.") %>
                    </span>
                    <span class="hidden sm:inline">
                      <%= Calendar.strftime(period.starts_on, "%d.%m.%Y") %>
                    </span>
                    -
                    <span class="sm:hidden">
                      <%= Calendar.strftime(period.ends_on, "%d.%m.") %>
                    </span>
                    <span class="hidden sm:inline">
                      <%= Calendar.strftime(period.ends_on, "%d.%m.%Y") %>
                    </span>
                  <% end %>
                </span>
              </td>
              <td class="px-2 sm:px-4 py-2 sm:py-3 text-sm">
                <% days = Date.diff(period.ends_on, period.starts_on) + 1 %>
                <% effective_duration = ViewHelpers.calculate_effective_duration(period, @all_periods) %>
                <% difference = effective_duration - days %>

                <%= days + difference %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>

      <% has_differences =
        Enum.any?(@periods, fn period ->
          days = Date.diff(period.ends_on, period.starts_on) + 1
          effective_duration = ViewHelpers.calculate_effective_duration(period, @all_periods)
          effective_duration != days
        end) %>

      <%= if has_differences do %>
        <div class="text-xs text-gray-500 mt-2">
          * Die effektive Dauer in Tagen enthält an die Ferien angrenzende Wochenenden und Feiertage.
        </div>
      <% end %>
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
  defp vacation_url(conn, period, federal_state) do
    case vacation_type_slug(period) do
      nil ->
        nil

      slug ->
        MehrSchulferienWeb.Router.Helpers.vacation_path(
          conn,
          String.to_atom(slug),
          federal_state.slug,
          period.starts_on.year
        )
    end
  end

  defp table_about_content(assigns) do
    parts = ["Schulferien"]
    parts = if assigns[:federal_state], do: parts ++ [assigns.federal_state.name], else: parts
    parts = if assigns[:year], do: parts ++ [assigns.year], else: parts
    Enum.join(parts, " ")
  end
end
