defmodule MehrSchulferienWeb.FederalState.CalendarLegendComponent do
  use Phoenix.Component

  def calendar_legend(assigns) do
    ~H"""
    <div class="mb-4 flex flex-wrap items-center gap-4 text-sm">
      <div class="flex items-center">
        <div class="w-4 h-4 bg-blue-100 border border-gray-200 mr-1"></div>
        <span>Feiertage</span>
      </div>
      <div class="flex items-center">
        <div class="w-4 h-4 bg-green-100 border border-gray-200 mr-1"></div>
        <span>Schulferien</span>
      </div>
      <div class="flex items-center">
        <div class="w-4 h-4 bg-gray-100 border border-gray-200 mr-1"></div>
        <span>Wochenenden</span>
      </div>
    </div>
    """
  end
end
