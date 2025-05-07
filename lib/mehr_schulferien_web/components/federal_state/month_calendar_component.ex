defmodule MehrSchulferienWeb.FederalState.MonthCalendarComponent do
  use Phoenix.Component

  import MehrSchulferienWeb.FederalState.MonthEventsComponent
  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferienWeb.FederalState.PartialDataComponent

  attr :month, :integer, required: true
  attr :year, :integer, required: true
  attr :periods, :list, required: true
  attr :public_periods, :list, required: true
  attr :all_periods, :list, required: true

  def month_calendar(assigns) do
    month_name =
      case assigns.month do
        1 -> "Januar"
        2 -> "Februar"
        3 -> "März"
        4 -> "April"
        5 -> "Mai"
        6 -> "Juni"
        7 -> "Juli"
        8 -> "August"
        9 -> "September"
        10 -> "Oktober"
        11 -> "November"
        12 -> "Dezember"
      end

    first_day_of_month = Date.new!(assigns.year, assigns.month, 1)
    first_weekday = Date.day_of_week(first_day_of_month)
    days_in_month = Date.days_in_month(first_day_of_month)
    month_id = "month-#{assigns.month}"

    # Use the more accurate function to determine if this month should be crossed out
    should_cross_out =
      PartialDataComponent.should_cross_out_month?(assigns.month, assigns.year, assigns.periods)

    # Filter periods for this month
    month_periods =
      Enum.filter(assigns.periods, fn period ->
        period.starts_on.month == assigns.month || period.ends_on.month == assigns.month ||
          (period.starts_on.month < assigns.month && period.ends_on.month > assigns.month)
      end)

    month_public_periods =
      Enum.filter(assigns.public_periods, fn period ->
        period.starts_on.month == assigns.month || period.ends_on.month == assigns.month ||
          (period.starts_on.month < assigns.month && period.ends_on.month > assigns.month)
      end)

    assigns =
      assign(assigns,
        month_name: month_name,
        first_day_of_month: first_day_of_month,
        first_weekday: first_weekday,
        days_in_month: days_in_month,
        month_id: month_id,
        month_periods: month_periods,
        month_public_periods: month_public_periods,
        start_day: 1 - (first_weekday - 1),
        should_cross_out: should_cross_out
      )

    ~H"""
    <section class="bg-white rounded shadow p-6 h-full" id={@month_id}>
      <div class={["bridge-day-timeline", @should_cross_out && "opacity-40"]}>
        <table class="border-collapse w-full table-fixed">
          <thead>
            <tr>
              <th
                class={[
                  "text-left py-0.5 pl-1 pr-0 font-semibold text-base border border-gray-200",
                  @should_cross_out && "bg-gray-200 text-gray-500",
                  !@should_cross_out && "bg-gray-50"
                ]}
                colspan="7"
              >
                <%= @month_name %> <%= @year %>
                <%= if @should_cross_out do %>
                  <span class="text-xs ml-2 text-gray-500 italic">(noch keine Daten)</span>
                <% end %>
              </th>
            </tr>
            <tr>
              <td class="bg-gray-50 text-[11px] p-0.5 font-normal h-5 border border-gray-200 text-center w-1/12">
                <%= DateHelpers.weekday(1, :short) %>
              </td>
              <td class="bg-gray-50 text-[11px] p-0.5 font-normal h-5 border border-gray-200 text-center w-1/12">
                <%= DateHelpers.weekday(2, :short) %>
              </td>
              <td class="bg-gray-50 text-[11px] p-0.5 font-normal h-5 border border-gray-200 text-center w-1/12">
                <%= DateHelpers.weekday(3, :short) %>
              </td>
              <td class="bg-gray-50 text-[11px] p-0.5 font-normal h-5 border border-gray-200 text-center w-1/12">
                <%= DateHelpers.weekday(4, :short) %>
              </td>
              <td class="bg-gray-50 text-[11px] p-0.5 font-normal h-5 border border-gray-200 text-center w-1/12">
                <%= DateHelpers.weekday(5, :short) %>
              </td>
              <td class="bg-gray-50 text-[11px] p-0.5 font-normal h-5 border border-gray-200 text-center w-1/12">
                <%= DateHelpers.weekday(6, :short) %>
              </td>
              <td class="bg-gray-50 text-[11px] p-0.5 font-normal h-5 border border-gray-200 text-center w-1/12">
                <%= DateHelpers.weekday(7, :short) %>
              </td>
            </tr>
          </thead>

          <tbody>
            <%= for week <- 0..5 do %>
              <% week_start_day = @start_day + week * 7
              # Check if this row has any valid days
              has_days =
                Enum.any?(1..7, fn weekday ->
                  day = week_start_day + weekday - 1
                  day > 0 and day <= @days_in_month
                end) %>
              <%= if has_days do %>
                <tr>
                  <%= for weekday <- 1..7 do %>
                    <% day = week_start_day + weekday - 1 %>
                    <% current_date =
                      if day > 0 and day <= @days_in_month do
                        Date.new!(@year, @month, day)
                      else
                        nil
                      end %>

                    <% is_public_holiday =
                      if current_date do
                        Enum.any?(@public_periods, fn period ->
                          Date.compare(period.starts_on, current_date) != :gt &&
                            Date.compare(period.ends_on, current_date) != :lt
                        end)
                      else
                        false
                      end %>

                    <% is_vacation =
                      if current_date do
                        Enum.any?(@periods, fn period ->
                          Date.compare(period.starts_on, current_date) != :gt &&
                            Date.compare(period.ends_on, current_date) != :lt
                        end)
                      else
                        false
                      end %>

                    <td class={[
                      "border border-gray-200 text-center py-1 w-1/12 text-xs h-[30px]",
                      cond do
                        is_public_holiday ->
                          MehrSchulferien.StyleConfig.get_class(:holiday, :tailwind, true)

                        is_vacation ->
                          MehrSchulferien.StyleConfig.get_class(:vacation, :tailwind, true)

                        weekday >= 6 ->
                          MehrSchulferien.StyleConfig.get_class(:weekend, :tailwind, true)

                        true ->
                          ""
                      end
                    ]}>
                      <%= if day > 0 and day <= @days_in_month do %>
                        <%= day %>.
                      <% end %>
                    </td>
                  <% end %>
                </tr>
              <% end %>
            <% end %>
          </tbody>
        </table>
      </div>

      <%= if length(@month_periods) > 0 || length(@month_public_periods) > 0 do %>
        <.month_events
          month_periods={@month_periods}
          month_public_periods={@month_public_periods}
          all_periods={@all_periods}
        />
      <% end %>
    </section>
    """
  end
end
