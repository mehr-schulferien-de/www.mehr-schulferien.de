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
    MehrSchulferienWeb.ViewHelpers.format_zip_codes(city)
  end
end
