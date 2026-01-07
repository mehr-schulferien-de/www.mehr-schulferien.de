defmodule MehrSchulferienWeb.VacationPlannerHTML do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "vacation_planner"

  use PhoenixHTMLHelpers

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  alias MehrSchulferien.Calendars.DateHelpers

  # Import shared components for unified design (used in templates)
  import MehrSchulferienWeb.Shared.TypographyComponent

  # Import vacation planner calendar components
  import MehrSchulferienWeb.VacationPlanner.VacationPlannerCalendarComponent
  import MehrSchulferienWeb.VacationPlanner.VacationPlannerLegendComponent

  @doc """
  Formats a date range for display.
  """
  def format_date_range(start_date, end_date) do
    months_map = DateHelpers.get_months_map()
    start_month = start_date.month
    end_month = end_date.month
    start_year = start_date.year
    end_year = end_date.year

    cond do
      start_year != end_year ->
        "#{start_date.day}. #{months_map[start_month]} #{start_year} – #{end_date.day}. #{months_map[end_month]} #{end_year}"

      start_month != end_month ->
        "#{start_date.day}. #{months_map[start_month]} – #{end_date.day}. #{months_map[end_month]} #{start_year}"

      true ->
        "#{start_date.day}. – #{end_date.day}. #{months_map[start_month]} #{start_year}"
    end
  end

  @doc """
  Formats the efficiency percentage with a + sign for positive values.
  """
  def format_efficiency(percentage) when percentage > 0 do
    "+#{percentage}%"
  end

  def format_efficiency(percentage) do
    "#{percentage}%"
  end

  @doc """
  Returns the appropriate CSS classes for an efficiency badge based on the percentage.
  """
  def efficiency_badge_class(percentage) when percentage >= 50 do
    "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400"
  end

  def efficiency_badge_class(percentage) when percentage >= 20 do
    "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400"
  end

  def efficiency_badge_class(_percentage) do
    "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300"
  end

  @doc """
  Formats the days parameter for URLs.
  """
  def format_days_url(days) do
    "#{days}-tage"
  end

  @doc """
  Returns the quick-select day options.
  """
  def quick_day_options do
    [5, 10, 14, 20, 25, 30]
  end

  @doc """
  Formats a list of holidays for display.
  """
  def format_holidays(holidays) when is_list(holidays) and length(holidays) > 0 do
    Enum.join(holidays, ", ")
  end

  def format_holidays(_), do: nil

  @doc """
  Returns the total number of calendar days in a result.
  """
  def calendar_days(result) do
    if result.start_date && result.end_date do
      Date.diff(result.end_date, result.start_date) + 1
    else
      0
    end
  end

  @doc """
  Checks if a result spans the Christmas/New Year period.

  Returns true if the result starts in December and ends in January of the next year.
  """
  def is_christmas_window?(result) do
    result.start_date.month == 12 and result.end_date.month == 1 and
      result.end_date.year == result.start_date.year + 1
  end
end
