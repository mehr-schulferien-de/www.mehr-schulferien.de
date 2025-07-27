defmodule MehrSchulferienWeb.FederalState.CalendarLegendComponent do
  use Phoenix.Component

  def calendar_legend(assigns) do
    ~H"""
    <div class="mb-4 flex flex-wrap items-center gap-4 text-sm text-gray-700 dark:text-gray-300">
      <div class="flex items-center">
        <div class="w-4 h-4 bg-blue-100 dark:bg-blue-600 border border-gray-200 dark:border-gray-700 mr-1"></div>
        <span>Feiertage</span>
      </div>
      <div class="flex items-center">
        <div class="w-4 h-4 bg-green-100 dark:bg-green-600 border border-gray-200 dark:border-gray-700 mr-1"></div>
        <span>Schulferien</span>
      </div>
      <div class="flex items-center">
        <div class="w-4 h-4 bg-gray-100 dark:bg-gray-700 border border-gray-200 dark:border-gray-700 mr-1"></div>
        <span>Wochenenden</span>
      </div>
    </div>
    """
  end
end
