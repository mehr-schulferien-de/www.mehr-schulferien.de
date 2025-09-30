defmodule MehrSchulferienWeb.DateQueryHTML do
  @moduledoc """
  This module contains pages for date queries.
  """
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/controllers",
    path: "date_query_html",
    namespace: MehrSchulferienWeb

  use PhoenixHTMLHelpers

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  # Import shared components for unified design
  import MehrSchulferienWeb.Shared.TypographyComponent
  import MehrSchulferienWeb.Shared.CardComponent
end
