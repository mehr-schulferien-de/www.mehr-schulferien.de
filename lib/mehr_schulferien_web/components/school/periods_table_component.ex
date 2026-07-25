defmodule MehrSchulferienWeb.School.PeriodsTableComponent do
  use Phoenix.Component

  import MehrSchulferienWeb.Shared.PeriodsTableBaseComponent

  attr :periods, :list, required: true
  attr :all_periods, :list, required: true
  attr :today, :any, default: Date.utc_today()
  attr :current_school_year, :integer, required: true
  attr :next_school_year, :integer, required: true

  def periods_table(assigns) do
    # Group by school year, then split each year into finished and still
    # relevant dates. Finished dates stay in the markup (they are what
    # long-tail searches like "Osterferien 2026 <Schule>" land on) but are
    # collapsed, so a visitor in the middle of the Sommerferien sees the
    # running vacation and the new school year first.
    grouped_periods =
      assigns.periods
      |> Enum.group_by(&school_year(&1.starts_on))
      |> Enum.filter(fn {year, _} ->
        year == assigns.current_school_year || year == assigns.next_school_year
      end)
      |> Enum.map(fn {year, periods} ->
        {past, upcoming} =
          periods
          |> Enum.sort_by(& &1.starts_on, Date)
          |> Enum.split_with(&past?(&1, assigns.today))

        %{
          school_year: year,
          past: past,
          upcoming: upcoming,
          badge: badge(year, assigns.current_school_year, upcoming, assigns.today)
        }
      end)
      |> Enum.sort_by(& &1.school_year, :asc)

    assigns = assign(assigns, :grouped_periods, grouped_periods)

    ~H"""
    <div>
      <div class="overflow-x-auto" tabindex="0" role="region" aria-label="Schulferien Tabelle">
        <%= for {group, index} <- Enum.with_index(@grouped_periods) do %>
          <div class={"mb-4 sm:mb-6 #{if index > 0, do: "mt-6 sm:mt-8 pt-4 sm:pt-6 border-t border-gray-300 dark:border-gray-600"}"}>
            <div class="flex items-center gap-2 sm:gap-3 mb-2 sm:mb-3">
              <h3 class="text-base sm:text-lg font-semibold text-gray-800 dark:text-gray-200">
                Schuljahr {group.school_year}/{group.school_year + 1}
              </h3>
              <span class={"inline-flex items-center px-2 py-0.5 rounded-full text-[10px] sm:text-xs font-medium #{elem(group.badge, 1)}"}>
                {elem(group.badge, 0)}
              </span>
            </div>

            <%= if group.past != [] do %>
              <details class="mb-2 sm:mb-3 group">
                <summary class="cursor-pointer text-xs sm:text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 select-none">
                  {past_summary_label(group.past)}
                </summary>
                <div class="mt-2">
                  <.period_table
                    periods={group.past}
                    all_periods={@all_periods}
                    today={@today}
                    current_school_year={@current_school_year}
                    school_year={group.school_year}
                    clickable={false}
                  />
                </div>
              </details>
            <% end %>

            <%= if group.upcoming != [] do %>
              <.period_table
                periods={group.upcoming}
                all_periods={@all_periods}
                today={@today}
                current_school_year={@current_school_year}
                school_year={group.school_year}
                clickable={true}
              />
            <% end %>
          </div>
        <% end %>

        <.periods_footnote periods={@periods} all_periods={@all_periods} />
      </div>
    </div>
    """
  end

  attr :periods, :list, required: true
  attr :all_periods, :list, required: true
  attr :today, :any, required: true
  attr :current_school_year, :integer, required: true
  attr :school_year, :integer, required: true
  attr :clickable, :boolean, required: true

  defp period_table(assigns) do
    ~H"""
    <table class="min-w-full bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 table-fixed rounded-lg overflow-hidden">
      <colgroup>
        <col class="w-1/2 sm:w-1/2" />
        <col class="w-5/12 sm:w-1/3" />
        <col class="w-1/12 sm:w-1/6" />
      </colgroup>
      <thead>
        <tr class={
          if @school_year != @current_school_year,
            do: "bg-blue-50 dark:bg-blue-950",
            else: "bg-gray-50 dark:bg-gray-900"
        }>
          <th class="px-2 sm:px-4 py-1.5 sm:py-3 text-left text-[10px] sm:text-xs font-medium text-gray-700 dark:text-gray-400 uppercase tracking-wider border-b dark:border-gray-600">
            Name
          </th>
          <th class="px-2 sm:px-4 py-1.5 sm:py-3 text-left text-[10px] sm:text-xs font-medium text-gray-700 dark:text-gray-400 uppercase tracking-wider border-b dark:border-gray-600">
            Termin
          </th>
          <th class="px-2 sm:px-4 py-1.5 sm:py-3 text-left text-[10px] sm:text-xs font-medium text-gray-700 dark:text-gray-400 uppercase tracking-wider border-b dark:border-gray-600">
            Tage
          </th>
        </tr>
      </thead>
      <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
        <%= for period <- @periods do %>
          <.period_row
            period={period}
            all_periods={@all_periods}
            today={@today}
            current_year={@current_school_year}
            show_mobile_dates={true}
            show_memo={true}
            show_year_in_dates={true}
            clickable={@clickable}
          />
        <% end %>
      </tbody>
    </table>
    """
  end

  defp past_summary_label([_single]), do: "1 vergangenen Termin anzeigen"
  defp past_summary_label(past), do: "#{length(past)} vergangene Termine anzeigen"

  # A school year keeps the green "Aktuell" badge only as long as something
  # is still ahead of it. Once the Sommerferien are the last thing left the
  # teaching year is over, which is what a visitor in July actually sees.
  defp badge(school_year, current_school_year, _upcoming, _today)
       when school_year != current_school_year do
    {"Kommend", "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"}
  end

  defp badge(_school_year, _current_school_year, [], _today) do
    {"Beendet", "bg-gray-200 text-gray-700 dark:bg-gray-700 dark:text-gray-300"}
  end

  defp badge(_school_year, _current_school_year, upcoming, today) do
    if Enum.all?(upcoming, &running?(&1, today)) do
      {"Läuft noch", "bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200"}
    else
      {"Aktuell", "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"}
    end
  end

  defp past?(period, today), do: Date.compare(period.ends_on, today) == :lt

  defp running?(period, today) do
    Date.compare(period.starts_on, today) != :gt && Date.compare(period.ends_on, today) != :lt
  end

  # A school year starts on August 1st
  defp school_year(date) do
    if date.month >= 8 do
      date.year
    else
      date.year - 1
    end
  end
end
