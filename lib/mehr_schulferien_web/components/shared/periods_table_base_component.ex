defmodule MehrSchulferienWeb.Shared.PeriodsTableBaseComponent do
  @moduledoc """
  Base component for displaying period tables.

  This component provides the common functionality for displaying periods
  in a table format, used by both school and federal state period tables.
  """

  use Phoenix.Component

  alias MehrSchulferienWeb.ViewHelpers
  alias MehrSchulferienWeb.Formatters.DateFormatter

  @month_names %{
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

  @doc """
  Renders a period table row.

  ## Attributes

  - `:period` - The period to display
  - `:all_periods` - All periods for effective duration calculation
  - `:today` - Current date for highlighting
  - `:current_year` - Current year for coloring next year periods
  - `:row_click_href` - Optional href for row click navigation
  - `:period_link_builder` - Optional function to build period link
  - `:show_mobile_dates` - Whether to show mobile-optimized dates
  - `:show_memo` - Whether to show period memo
  - `:show_year_in_dates` - Whether to always show year in dates for clarity
  """
  attr :period, :map, required: true
  attr :all_periods, :list, required: true
  attr :today, :any, default: Date.utc_today()
  attr :current_year, :integer, default: nil
  attr :row_click_href, :string, default: nil
  attr :period_link_builder, :any, default: nil
  attr :show_mobile_dates, :boolean, default: false
  attr :show_memo, :boolean, default: false
  attr :show_year_in_dates, :boolean, default: false

  slot :period_name do
    attr :class, :string
  end

  def period_row(assigns) do
    # Calculate derived values
    is_current =
      Date.compare(assigns.today, assigns.period.starts_on) != :lt &&
        Date.compare(assigns.today, assigns.period.ends_on) != :gt

    is_past = Date.compare(assigns.today, assigns.period.ends_on) == :gt

    period_year = assigns.period.starts_on.year
    is_next_year = assigns.current_year && period_year > assigns.current_year

    month_name = @month_names[assigns.period.starts_on.month]

    days = Date.diff(assigns.period.ends_on, assigns.period.starts_on) + 1

    effective_duration =
      ViewHelpers.calculate_effective_duration(assigns.period, assigns.all_periods)

    row_href = assigns.row_click_href || "##{month_name}#{period_year}"

    assigns =
      assigns
      |> assign(:is_current, is_current)
      |> assign(:is_past, is_past)
      |> assign(:is_next_year, is_next_year)
      |> assign(:days, days)
      |> assign(:effective_duration, effective_duration)
      |> assign(:row_href, row_href)

    ~H"""
    <tr
      class={"hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer #{if @is_current, do: "bg-yellow-100 dark:bg-yellow-900"} #{if @is_past, do: "text-gray-400 dark:text-gray-500"} #{if @is_next_year, do: "bg-gray-50 dark:bg-gray-900"}"}
      onclick={"window.location.href='#{@row_href}'"}
    >
      <td class="px-2 sm:px-4 py-2 sm:py-3 text-sm font-medium align-top">
        <%= if @period_link_builder do %>
          <a
            href={@period_link_builder.(@period)}
            class="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 underline"
          >
            {render_slot(@period_name) || render_period_name(assigns)}
          </a>
        <% else %>
          {render_slot(@period_name) || render_period_name(assigns)}
        <% end %>

        <%= if @show_memo && @period.holiday_or_vacation_type.name == "Beweglicher Ferientag" && @period.memo && @period.memo != "" do %>
          <div class="text-xs text-gray-600 dark:text-gray-400 mt-1">
            {clean_beweglicher_ferientag_memo(@period.memo)}
          </div>
        <% end %>
      </td>
      <td class="px-2 sm:px-4 py-2 sm:py-3 text-sm align-top">
        <%= if @show_mobile_dates do %>
          <.mobile_date_display
            period={@period}
            is_next_year={@is_next_year}
            show_year_in_dates={@show_year_in_dates}
          />
        <% else %>
          <.simple_date_display
            period={@period}
            is_next_year={@is_next_year}
            show_year_in_dates={@show_year_in_dates}
          />
        <% end %>
      </td>
      <td class="px-2 sm:px-4 py-2 sm:py-3 text-sm text-right align-top">
        {@effective_duration}
      </td>
    </tr>
    """
  end

  @doc """
  Renders the period table footnote about effective duration.
  """
  attr :periods, :list, required: true
  attr :all_periods, :list, required: true

  def periods_footnote(assigns) do
    has_differences =
      Enum.any?(assigns.periods, fn period ->
        days = Date.diff(period.ends_on, period.starts_on) + 1
        effective_duration = ViewHelpers.calculate_effective_duration(period, assigns.all_periods)
        effective_duration != days
      end)

    assigns = assign(assigns, :has_differences, has_differences)

    ~H"""
    <%= if @has_differences do %>
      <div class="text-xs text-gray-500 dark:text-gray-400 mt-2">
        * Die effektive Dauer in Tagen enthält an die Ferien angrenzende Wochenenden und Feiertage.
      </div>
    <% end %>
    """
  end

  @doc """
  Renders a simple date display for periods.
  """
  attr :period, :map, required: true
  attr :is_next_year, :boolean, default: false
  attr :show_year_in_dates, :boolean, default: false

  def simple_date_display(assigns) do
    ~H"""
    <span class="whitespace-nowrap">
      <%= if Date.compare(@period.starts_on, @period.ends_on) == :eq do %>
        <%= if @show_year_in_dates || @period.starts_on.year != @period.ends_on.year do %>
          {DateFormatter.format_date_full(@period.starts_on)}
        <% else %>
          {DateFormatter.format_date_with_short_year(@period.starts_on)}
        <% end %>
      <% else %>
        <%= if @show_year_in_dates || @period.starts_on.year != @period.ends_on.year do %>
          {DateFormatter.format_date_full(@period.starts_on)} - {DateFormatter.format_date_full(
            @period.ends_on
          )}
        <% else %>
          {DateFormatter.format_date_with_short_year(@period.starts_on)} - {DateFormatter.format_date_with_short_year(
            @period.ends_on
          )}
        <% end %>
      <% end %>
    </span>
    """
  end

  @doc """
  Renders a mobile-optimized date display with responsive behavior.
  """
  attr :period, :map, required: true
  attr :is_next_year, :boolean, default: false
  attr :show_year_in_dates, :boolean, default: false

  def mobile_date_display(assigns) do
    ~H"""
    <div>
      <%= if Date.compare(@period.starts_on, @period.ends_on) == :eq do %>
        <span class="sm:hidden whitespace-nowrap">
          <%= if @show_year_in_dates do %>
            {DateFormatter.format_date_full(@period.starts_on)}
          <% else %>
            {DateFormatter.format_date_with_short_year(@period.starts_on)}
          <% end %>
        </span>
        <span class="hidden sm:inline whitespace-nowrap">
          {DateFormatter.format_date_full(@period.starts_on)}
        </span>
      <% else %>
        <div class="sm:hidden">
          <%= if @show_year_in_dates do %>
            <span class="whitespace-nowrap">{DateFormatter.format_date_full(@period.starts_on)}</span>
            <span class="whitespace-nowrap">- {DateFormatter.format_date_full(@period.ends_on)}</span>
          <% else %>
            <span class="whitespace-nowrap">
              {DateFormatter.format_date_with_short_year(@period.starts_on)}
            </span>
            <span class="whitespace-nowrap">
              - {DateFormatter.format_date_with_short_year(@period.ends_on)}
            </span>
          <% end %>
        </div>
        <span class="hidden sm:inline whitespace-nowrap">
          {DateFormatter.format_date_full(@period.starts_on)} - {DateFormatter.format_date_full(
            @period.ends_on
          )}
        </span>
      <% end %>
    </div>
    """
  end

  # Private helpers

  defp render_period_name(assigns) do
    import MehrSchulferienWeb.FederalState.PeriodNameComponent

    assigns = Map.new(assigns)

    ~H"""
    <.period_name period={@period} />
    """
  end

  defp clean_beweglicher_ferientag_memo(memo) do
    cleaned_memo = String.trim(memo)

    if String.downcase(cleaned_memo) |> String.starts_with?("beweglicher ferientag") do
      cleaned_memo
      |> String.replace_prefix("beweglicher Ferientag", "")
      |> String.replace_prefix("Beweglicher Ferientag", "")
      |> String.replace_prefix("beweglicher ferientag", "")
      |> String.replace_prefix("Beweglicher ferientag", "")
      |> String.trim()
    else
      cleaned_memo
    end
  end

  @doc """
  Gets the month name for a given month number.
  """
  def month_name(month_number), do: @month_names[month_number]
end
