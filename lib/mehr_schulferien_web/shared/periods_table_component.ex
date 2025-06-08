defmodule MehrSchulferienWeb.Shared.PeriodsTableComponent do
  use Phoenix.Component

  alias MehrSchulferienWeb.ViewHelpers

  attr :periods, :list, required: true
  attr :all_periods, :list, required: true
  attr :today, :any, default: Date.utc_today()
  attr :group_by_school_year, :boolean, default: false
  attr :anchor_link_format, :string, default: "month_name_year"

  def render_periods_table(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200 bg-white">
        <thead class="bg-gray-50">
          <tr>
            <th
              scope="col"
              class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
            >
              Ferien
            </th>
            <th
              scope="col"
              class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider"
            >
              Zeitraum
            </th>
            <th
              scope="col"
              class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
            >
              Dauer
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <% grouped_periods = get_grouped_periods(@periods, @group_by_school_year) %>
          <%= for periods <- grouped_periods do %>
            <% period = Enum.at(periods, 0) %>
            <tr class={[
              "hover:bg-gray-50",
              cond do
                period.html_class in ["warning", "danger"] -> period.html_class
                true -> ""
              end
            ]}>
              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                <%= period.holiday_or_vacation_type.colloquial %> <%= period.starts_on.year %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center">
                <span>
                  <% anchor = get_anchor_link(period, @anchor_link_format) %>
                  <a href={"##{anchor}"} class="text-blue-600 hover:text-blue-800 cursor-pointer">
                    <%= for period <- periods do %>
                      <%= ViewHelpers.format_date_range(period.starts_on, period.ends_on, :short) %>
                      <%= if Enum.count(periods) > 1 && List.last(periods) != period do %>
                        ,
                      <% end %>
                    <% end %>
                  </a>
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-right">
                <%= ViewHelpers.number_days(periods) %>&nbsp;Tag<%= if ViewHelpers.number_days(periods) > 1 do %>
                  e
                <% end %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp get_grouped_periods(periods, true) do
    # Group by school year for schools (August of year-1 to July of year)
    group_periods_by_school_year(periods)
  end

  defp get_grouped_periods(periods, false) do
    # Group by single year for federal states
    MehrSchulferien.Periods.group_periods_single_year(periods)
  end

  # Custom implementation for school year grouping
  defp group_periods_by_school_year(periods) do
    # Group periods by school year, then by vacation type
    periods
    |> Enum.group_by(fn period ->
      # School year starts in August
      if period.starts_on.month >= 8 do
        period.starts_on.year
      else
        period.starts_on.year - 1
      end
    end)
    |> Enum.flat_map(fn {_school_year, year_periods} ->
      # Within each school year, group by vacation type
      year_periods
      |> Enum.chunk_by(& &1.holiday_or_vacation_type.name)
    end)
  end

  defp get_anchor_link(period, "month_number") do
    "#{period.starts_on.month}_#{period.starts_on.year}"
  end

  defp get_anchor_link(period, "month_name_year") do
    months = %{
      1 => "januar",
      2 => "februar",
      3 => "märz",
      4 => "april",
      5 => "mai",
      6 => "juni",
      7 => "juli",
      8 => "august",
      9 => "september",
      10 => "oktober",
      11 => "november",
      12 => "dezember"
    }

    month_name = Map.get(months, period.starts_on.month, "")
    "#{month_name}#{period.starts_on.year}"
  end

  defp get_anchor_link(period, _) do
    # Default format
    get_anchor_link(period, "month_name_year")
  end
end
