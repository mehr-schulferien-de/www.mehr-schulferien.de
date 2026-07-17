defmodule MehrSchulferienWeb.VacationView do
  use MehrSchulferienWeb, :view

  import MehrSchulferienWeb.Shared.GenericPaginationComponent
  import MehrSchulferienWeb.FederalState.PeriodsTableComponent
  import MehrSchulferienWeb.FederalState.CalendarLegendComponent
  import MehrSchulferienWeb.FederalState.MonthCalendarComponent
  import MehrSchulferienWeb.ICalPanelComponent
  import MehrSchulferienWeb.FederalStateComponents
  import MehrSchulferienWeb.FederalState.LastUpdatedComponent

  import MehrSchulferienWeb.VacationHelpers
end
