defmodule MehrSchulferienWeb.VacationHTML do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "vacation"

  # Basic view imports
  use PhoenixHTMLHelpers

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  # Import shared components for unified design
  import MehrSchulferienWeb.Shared.TypographyComponent
  import MehrSchulferienWeb.Shared.CardComponent

  import MehrSchulferienWeb.Shared.GenericPaginationComponent
  import MehrSchulferienWeb.FederalState.PeriodsTableComponent
  import MehrSchulferienWeb.FederalState.CalendarLegendComponent
  import MehrSchulferienWeb.FederalState.MonthCalendarComponent
  import MehrSchulferienWeb.ICalPanelComponent
  import MehrSchulferienWeb.FederalStateComponents
  import MehrSchulferienWeb.FederalState.LastUpdatedComponent

  import MehrSchulferienWeb.VacationHelpers
end
