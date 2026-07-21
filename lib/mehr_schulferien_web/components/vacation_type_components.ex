defmodule MehrSchulferienWeb.VacationTypeComponents do
  @moduledoc """
  Shared components for vacation type overview pages
  """
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  alias MehrSchulferienWeb.Formatters.DateFormatter

  # Private helper functions

  defp calculate_vacation_stats(vacation_data) do
    valid_data = Enum.filter(vacation_data, &(&1.period != nil))

    case valid_data do
      [] ->
        nil

      [earliest | _] = data ->
        latest = Enum.max_by(data, fn %{period: p} -> p.starts_on end)
        latest_end = Enum.max_by(data, fn %{period: p} -> p.ends_on end)

        {min_duration, max_duration} =
          Enum.min_max_by(data, & &1.duration)
          |> then(fn {min, max} -> {min.duration, max.duration} end)

        %{
          earliest_state: earliest.state_name,
          earliest_date: format_date(earliest.period.starts_on),
          latest_state: latest.state_name,
          latest_date: format_date(latest.period.starts_on),
          min_duration: min_duration,
          max_duration: max_duration,
          total_days: Date.diff(latest_end.period.ends_on, earliest.period.starts_on) + 1
        }
    end
  end

  defp format_date(date) do
    DateFormatter.format_date_full(date)
  end

  @doc """
  Renders a table showing all federal states' vacation dates
  """
  attr :vacation_data, :list, required: true
  attr :vacation_type, :string, required: true
  attr :year, :integer, required: true
  attr :conn, :any, required: true

  def vacation_overview_table(assigns) do
    ~H"""
    <!-- Mobile: Card Layout -->
    <div class="md:hidden space-y-3">
      <%= for data <- @vacation_data do %>
        <div id={data.state_slug} class="bg-white shadow rounded-lg p-4 border border-gray-200">
          <div class="flex items-start justify-between mb-3">
            <div>
              <h3 class="text-base font-semibold text-gray-900">{data.state_name}</h3>
              <p class="text-xs text-gray-500">({data.state_code})</p>
            </div>
            <%= if data.duration > 0 do %>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                {data.duration} Tage
              </span>
            <% end %>
          </div>

          <dl class="space-y-2">
            <div class="flex justify-between text-sm">
              <dt class="font-medium text-gray-500">Beginn:</dt>
              <dd class="text-gray-900">
                <%= if data.period do %>
                  <time datetime={data.period.starts_on}>{data.start_date}</time>
                <% else %>
                  <span class="text-gray-400">-</span>
                <% end %>
              </dd>
            </div>
            <div class="flex justify-between text-sm">
              <dt class="font-medium text-gray-500">Ende:</dt>
              <dd class="text-gray-900">
                <%= if data.period do %>
                  <time datetime={data.period.ends_on}>{data.end_date}</time>
                <% else %>
                  <span class="text-gray-400">-</span>
                <% end %>
              </dd>
            </div>
          </dl>

          <%= if data.period && MehrSchulferien.Calendars.VacationTypes.exists_for_year?(data.state, @vacation_type, @year) do %>
            <div class="mt-3 pt-3 border-t border-gray-200">
              <a
                href={"/#{MehrSchulferien.Calendars.VacationSlug.url_slug(@vacation_type)}/#{data.state_slug}/#{@year}"}
                class="text-sm text-blue-600 hover:text-blue-900 font-medium"
              >
                Details anzeigen →
              </a>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    <!-- Desktop: Table Layout -->
    <div class="hidden md:block overflow-x-auto shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
      <table class="min-w-full divide-y divide-gray-300">
        <thead class="bg-gray-50">
          <tr>
            <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
              Bundesland
            </th>
            <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
              Beginn
            </th>
            <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
              Ende
            </th>
            <th scope="col" class="px-3 py-3.5 text-center text-sm font-semibold text-gray-900">
              Dauer
            </th>
            <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-6">
              <span class="sr-only">Details</span>
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-200 bg-white">
          <%= for {data, index} <- Enum.with_index(@vacation_data) do %>
            <tr
              id={"#{data.state_slug}-desktop"}
              class={if rem(index, 2) == 0, do: "bg-white", else: "bg-gray-50"}
            >
              <td class="whitespace-nowrap px-3 py-4 text-sm font-medium text-gray-900">
                {data.state_name}
                <span class="ml-1 text-xs text-gray-500">({data.state_code})</span>
              </td>
              <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                <%= if data.period do %>
                  <time datetime={data.period.starts_on}>
                    {data.start_date}
                  </time>
                <% else %>
                  <span class="text-gray-400">-</span>
                <% end %>
              </td>
              <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                <%= if data.period do %>
                  <time datetime={data.period.ends_on}>
                    {data.end_date}
                  </time>
                <% else %>
                  <span class="text-gray-400">-</span>
                <% end %>
              </td>
              <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500 text-center">
                <%= if data.duration > 0 do %>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                    {data.duration} Tage
                  </span>
                <% else %>
                  <span class="text-gray-400">-</span>
                <% end %>
              </td>
              <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                <%= if data.period && MehrSchulferien.Calendars.VacationTypes.exists_for_year?(data.state, @vacation_type, @year) do %>
                  <a
                    href={"/#{MehrSchulferien.Calendars.VacationSlug.url_slug(@vacation_type)}/#{data.state_slug}/#{@year}"}
                    class="text-blue-600 hover:text-blue-900"
                  >
                    Details <span class="sr-only">für {data.state_name}</span>
                  </a>
                <% end %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders vacation type statistics
  """
  attr :vacation_data, :list, required: true
  attr :vacation_name, :string, required: true

  def vacation_statistics(assigns) do
    stats = calculate_vacation_stats(assigns.vacation_data)
    assigns = assign(assigns, :stats, stats)

    ~H"""
    <%= if @stats do %>
      <div class="bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
            {@vacation_name} auf einen Blick
          </h3>
          <dl class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
            <div class="px-4 py-5 bg-gray-50 shadow rounded-lg overflow-hidden sm:p-6">
              <dt class="text-sm font-medium text-gray-500 truncate">
                Frühester Beginn
              </dt>
              <dd class="mt-1 text-lg font-semibold text-gray-900">
                {@stats.earliest_date}
                <span class="text-sm font-normal text-gray-500">({@stats.earliest_state})</span>
              </dd>
            </div>

            <div class="px-4 py-5 bg-gray-50 shadow rounded-lg overflow-hidden sm:p-6">
              <dt class="text-sm font-medium text-gray-500 truncate">
                Spätester Beginn
              </dt>
              <dd class="mt-1 text-lg font-semibold text-gray-900">
                {@stats.latest_date}
                <span class="text-sm font-normal text-gray-500">({@stats.latest_state})</span>
              </dd>
            </div>

            <div class="px-4 py-5 bg-gray-50 shadow rounded-lg overflow-hidden sm:p-6">
              <dt class="text-sm font-medium text-gray-500 truncate">
                Gesamtzeitraum
              </dt>
              <dd class="mt-1 text-lg font-semibold text-gray-900">
                {@stats.total_days} Tage
                <span class="text-sm font-normal text-gray-500">
                  <%= if @stats.min_duration == @stats.max_duration do %>
                    (je {@stats.min_duration} Tage Ferien)
                  <% else %>
                    ({@stats.min_duration}-{@stats.max_duration} Tage Ferien)
                  <% end %>
                </span>
              </dd>
            </div>
          </dl>
        </div>
      </div>
    <% end %>
    """
  end

  # Planning tips for each vacation type
  @planning_tips %{
    "sommer" => [
      "Buchen Sie Unterkünfte frühzeitig - besonders für beliebte Reiseziele",
      "Vergleichen Sie die Ferientermine, um Hauptreisezeiten zu vermeiden",
      "Nutzen Sie die frühen oder späten Termine für günstigere Preise",
      "Beachten Sie die Staugefahr an den Wochenenden zu Ferienbeginn"
    ],
    "ostern" => [
      "Perfekt für Städtereisen in der Nebensaison",
      "Ostermärkte und Frühlingsveranstaltungen besuchen",
      "Erste Wanderungen und Radtouren des Jahres planen",
      "Kurzurlaube mit verlängerten Wochenenden kombinieren"
    ],
    "herbst" => [
      "Ideale Zeit für Wanderurlaube in bunter Natur",
      "Weinlesefeste und Erntedankfeiern besuchen",
      "Letzte Chance für Campingurlaube vor dem Winter",
      "Städtereisen bei angenehmen Temperaturen"
    ],
    "weihnachten" => [
      "Frühzeitig Skiurlaube und Winterreisen buchen",
      "Weihnachtsmärkte in verschiedenen Städten besuchen",
      "Silvesterreisen rechtzeitig planen",
      "Familienbesuche und Urlaubstage koordinieren"
    ],
    "winter" => [
      "Hauptsaison für Wintersport - früh buchen",
      "Faschingsveranstaltungen in die Planung einbeziehen",
      "Alternative: Flucht in wärmere Gefilde",
      "Wellness-Urlaube als Alternative zum Skifahren"
    ],
    "pfingsten" => [
      "Verlängerte Wochenenden optimal nutzen",
      "Kurztrips und Städtereisen ideal",
      "Erste Badesaison an Nord- und Ostsee",
      "Pfingstveranstaltungen und Volksfeste besuchen"
    ]
  }

  @doc """
  Renders vacation planning tips specific to vacation type
  """
  attr :vacation_type, :string, required: true

  def vacation_planning_tips(assigns) do
    tips = Map.get(@planning_tips, assigns.vacation_type, [])
    assigns = assign(assigns, :tips, tips)

    ~H"""
    <%= if @tips != [] do %>
      <div class="bg-blue-50 border-l-4 border-blue-400 p-4 my-6">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg
              class="h-5 w-5 text-blue-400"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
              role="img"
            >
              <title>Info-Symbol</title>
              <path
                fill-rule="evenodd"
                d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                clip-rule="evenodd"
              />
            </svg>
          </div>
          <div class="ml-3">
            <h3 class="text-sm font-medium text-blue-800">Planungstipps</h3>
            <div class="mt-2 text-sm text-blue-700">
              <ul class="list-disc list-inside space-y-1">
                <%= for tip <- @tips do %>
                  <li>{tip}</li>
                <% end %>
              </ul>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  @doc """
  Renders structured data scripts (list of ItemLists for multiple years)
  """
  attr :structured_data, :list, required: true

  def vacation_structured_data(assigns) do
    ~H"""
    <%= for item <- @structured_data do %>
      <script type="application/ld+json">
        <%= Phoenix.HTML.raw(Jason.encode!(item)) %>
      </script>
    <% end %>
    """
  end
end
