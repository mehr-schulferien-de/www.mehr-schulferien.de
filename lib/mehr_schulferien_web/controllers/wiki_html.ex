defmodule MehrSchulferienWeb.WikiHTML do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "wiki"

  # Basic view imports
  use PhoenixHTMLHelpers
  import MehrSchulferienWeb.ErrorHelpers
  import MehrSchulferienWeb.Helpers.UrlHelpers

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  # Import shared components for unified design
  import MehrSchulferienWeb.Shared.TypographyComponent
  import MehrSchulferienWeb.Shared.CardComponent

  alias MehrSchulferienWeb.Shared.DesignTokens

  import MehrSchulferienWeb.WikiHelpers
end
