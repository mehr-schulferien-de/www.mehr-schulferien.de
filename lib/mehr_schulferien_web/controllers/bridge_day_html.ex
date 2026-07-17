defmodule MehrSchulferienWeb.BridgeDayHTML do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "bridge_day"

  # Basic view imports
  use PhoenixHTMLHelpers

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  alias MehrSchulferienWeb.ViewHelpers

  # Import shared components for unified design
  import MehrSchulferienWeb.Shared.TypographyComponent

  import MehrSchulferienWeb.BridgeDayHelpers
end
