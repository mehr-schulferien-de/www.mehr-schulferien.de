defmodule MehrSchulferienWeb.School.PeriodsTableComponent do
  use Phoenix.Component

  alias MehrSchulferienWeb.ViewHelpers
  import MehrSchulferienWeb.FederalState.PeriodNameComponent

  attr :periods, :list, required: true
  attr :all_periods, :list, required: true
  attr :today, :any, default: Date.utc_today()
  attr :current_school_year, :integer, required: true
  attr :next_school_year, :integer, required: true

  def periods_table(assigns) do
    # Group periods by school year and filter to only current and next school year
    grouped_periods =
      Enum.group_by(assigns.periods, fn period ->
        get_school_year(period.starts_on)
      end)
      |> Enum.filter(fn {year, _} ->
        year == assigns.current_school_year || year == assigns.next_school_year
      end)
      |> Enum.sort_by(fn {year, _} -> year end, :asc)

    assigns = assign(assigns, :grouped_periods, grouped_periods)

    ~H"""
    <div>
      <div class="overflow-x-auto">
        <%= for {school_year, periods} <- @grouped_periods do %>
          <div class="mb-6">
            <h3 class="text-lg font-semibold text-gray-800 mb-2">
              Schuljahr <%= school_year %>/<%= school_year + 1 %>
            </h3>

            <table class="min-w-full bg-white border border-gray-200 table-fixed">
              <colgroup>
                <col class="w-1/2" />
                <col class="w-1/3" />
                <col class="w-1/6" />
              </colgroup>
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
                <%= for period <- Enum.sort_by(periods, & &1.starts_on, Date) do %>
                  <% is_current =
                    Date.compare(@today, period.starts_on) != :lt &&
                      Date.compare(@today, period.ends_on) != :gt

                  is_past =
                    Date.compare(@today, period.ends_on) == :gt

                  month_name =
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
                      <.period_name period={period} />
                      <%= if period.holiday_or_vacation_type.name == "Beweglicher Ferientag" && period.memo && period.memo != "" do %>
                        <div class="text-xs text-gray-600 mt-1">
                          <%= # Remove "beweglicher Ferientag" from the beginning of the memo (case insensitive)
                          cleaned_memo = String.trim(period.memo)

                          if String.downcase(cleaned_memo)
                             |> String.starts_with?("beweglicher ferientag") do
                            cleaned_memo
                            |> String.replace_prefix("beweglicher Ferientag", "")
                            |> String.replace_prefix("Beweglicher Ferientag", "")
                            |> String.replace_prefix("beweglicher ferientag", "")
                            |> String.replace_prefix("Beweglicher ferientag", "")
                            |> String.trim()
                          else
                            cleaned_memo
                          end %>
                        </div>
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
                      <% effective_duration =
                        ViewHelpers.calculate_effective_duration(period, @all_periods) %>
                      <% difference = effective_duration - days %>

                      <%= days + difference %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% end %>

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
    </div>
    """
  end

  # Helper function to determine school year
  # A school year starts on August 1st
  defp get_school_year(date) do
    if date.month >= 8 do
      date.year
    else
      date.year - 1
    end
  end
end
