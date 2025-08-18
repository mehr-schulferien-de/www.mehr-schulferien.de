defmodule MehrSchulferienWeb.CountryHTML do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "country"

  # Basic view imports
  use PhoenixHTMLHelpers

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  # Import shared components for unified design
  import MehrSchulferienWeb.Shared.TypographyComponent
  import MehrSchulferienWeb.Shared.CardComponent
end
