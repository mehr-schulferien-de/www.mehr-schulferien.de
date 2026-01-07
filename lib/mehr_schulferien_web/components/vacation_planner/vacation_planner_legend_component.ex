defmodule MehrSchulferienWeb.VacationPlanner.VacationPlannerLegendComponent do
  @moduledoc """
  Legend component for the vacation planner calendar showing the color coding.
  """
  use Phoenix.Component

  @doc """
  Renders a legend explaining the color coding of the vacation planner calendar.

  - Orange/Yellow: Vacation days (days you need to take off work)
  - Orange/Yellow with stripes: Vacation days during school vacations (more expensive travel)
  - Green: School vacation days (not user vacation days)
  - Blue: Public holidays (free days)
  - Gray: Weekend days (free days)
  """
  def vacation_planner_legend(assigns) do
    ~H"""
    <div class="mb-4 flex flex-wrap items-center gap-4 text-sm text-gray-700 dark:text-gray-300">
      <div class="flex items-center">
        <div class="w-4 h-4 bg-yellow-200 dark:bg-yellow-900 border border-gray-200 dark:border-gray-700 mr-1">
        </div>
        <span>Urlaubstage</span>
      </div>
      <div class="flex items-center">
        <div class="w-4 h-4 bg-yellow-200 dark:bg-yellow-900 border border-gray-200 dark:border-gray-700 mr-1 vacation-in-school-vacation">
        </div>
        <span>Urlaubstage in Schulferien</span>
      </div>
      <div class="flex items-center">
        <div class="w-4 h-4 bg-green-200 dark:bg-green-900 border border-gray-200 dark:border-gray-700 mr-1">
        </div>
        <span>Schulferien</span>
      </div>
      <div class="flex items-center">
        <div class="w-4 h-4 bg-blue-200 dark:bg-blue-900 border border-gray-200 dark:border-gray-700 mr-1">
        </div>
        <span>Feiertage</span>
      </div>
      <div class="flex items-center">
        <div class="w-4 h-4 bg-gray-200 dark:bg-gray-600 border border-gray-200 dark:border-gray-700 mr-1">
        </div>
        <span>Wochenenden</span>
      </div>
    </div>
    """
  end
end
