defmodule MehrSchulferienWeb.CityHTML do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "city"

  # Basic view imports
  use PhoenixHTMLHelpers

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  alias MehrSchulferienWeb.ViewHelpers

  # Import shared components for unified design
  import MehrSchulferienWeb.Shared.TypographyComponent
  import MehrSchulferienWeb.Shared.CardComponent

  # Import the components we need for our templates
  import MehrSchulferienWeb.Shared.GenericPaginationComponent
  import MehrSchulferienWeb.FederalState.PeriodsTableComponent
  import MehrSchulferienWeb.FederalState.CalendarLegendComponent
  import MehrSchulferienWeb.FederalState.MonthCalendarComponent
  import MehrSchulferienWeb.FederalState.NoDataComponent
  import MehrSchulferienWeb.FederalState.PartialDataComponent
  import MehrSchulferienWeb.CityComponents
  import MehrSchulferienWeb.FaqComponent

  def format_zip_codes(city) do
    MehrSchulferienWeb.ViewHelpers.format_zip_codes(city)
  end
end
