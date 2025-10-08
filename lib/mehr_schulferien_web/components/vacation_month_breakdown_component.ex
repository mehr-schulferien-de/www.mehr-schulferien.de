defmodule MehrSchulferienWeb.VacationMonthBreakdownComponent do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  import MehrSchulferienWeb.Shared.TypographyComponent

  attr :vacation_type, :string, required: true
  attr :vacation_config, :map, required: true
  attr :current_year, :integer, required: true
  attr :current_year_data, :list, required: true

  def vacation_month_breakdown(assigns) do
    # Group states by month
    assigns = assign(assigns, :months_with_states, group_by_month(assigns.current_year_data))

    ~H"""
    <section class="mt-12 bg-blue-50 dark:bg-blue-900 rounded-lg p-6">
      <.heading level={3} class="text-xl mb-4">
        {@vacation_config.name} {@current_year} - Übersicht nach Monaten
      </.heading>
      <p class="text-sm text-gray-700 dark:text-gray-300 mb-4">
        Finden Sie heraus, in welchem Monat die {@vacation_config.name} in den verschiedenen Bundesländern stattfinden.
      </p>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <%= for {month_name, states} <- @months_with_states do %>
          <div class="bg-white dark:bg-gray-800 rounded-lg p-4 shadow-sm">
            <.heading level={4} class="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-2">
              {month_name}
            </.heading>
            <ul class="space-y-1">
              <%= for state_info <- states do %>
                <li class="text-sm text-gray-700 dark:text-gray-300">
                  <a
                    href={"/#{@vacation_type}ferien/#{state_info.state.slug}/#{@current_year}"}
                    class="hover:text-blue-600 dark:hover:text-blue-400 hover:underline"
                  >
                    {state_info.state.name}
                  </a>
                  <span class="text-xs text-gray-500">
                    ({format_date_range(state_info.period)})
                  </span>
                </li>
              <% end %>
            </ul>
          </div>
        <% end %>
      </div>
    </section>
    """
  end

  defp group_by_month(states_data) do
    valid_states = Enum.filter(states_data, &(&1.period != nil))

    valid_states
    |> Enum.group_by(fn state_info ->
      Calendar.strftime(state_info.period.starts_on, "%B")
    end)
    |> Enum.sort_by(
      fn {_month_name, states} ->
        # Sort by the earliest start date in each month group
        states
        |> Enum.map(& &1.period.starts_on)
        |> Enum.min(Date)
      end,
      Date
    )
  end

  defp format_date_range(period) do
    start_day = Calendar.strftime(period.starts_on, "%-d.")
    end_day = Calendar.strftime(period.ends_on, "%-d.")
    "#{start_day}-#{end_day}"
  end
end
