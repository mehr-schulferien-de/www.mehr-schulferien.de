defmodule MehrSchulferienWeb.CityView do
  use MehrSchulferienWeb, :view

  # Import the components we need for our templates
  import MehrSchulferienWeb.Shared.GenericPaginationComponent
  import MehrSchulferienWeb.FederalState.PeriodsTableComponent
  import MehrSchulferienWeb.FederalState.CalendarLegendComponent
  import MehrSchulferienWeb.FederalState.MonthCalendarComponent
  import MehrSchulferienWeb.FederalState.NoDataComponent
  import MehrSchulferienWeb.FederalState.PartialDataComponent
  import MehrSchulferienWeb.CityComponents
  import MehrSchulferienWeb.FaqComponent
  import MehrSchulferienWeb.ICalPanelComponent

  def format_zip_codes(city) do
    "#{Enum.map(city.zip_codes, & &1.value) |> Enum.sort() |> MehrSchulferienWeb.ViewHelpers.comma_join_with_a_final_und()}"
  end

  def calculate_effective_duration(period, periods) do
    MehrSchulferienWeb.ViewHelpers.calculate_effective_duration(period, periods)
  end
end
