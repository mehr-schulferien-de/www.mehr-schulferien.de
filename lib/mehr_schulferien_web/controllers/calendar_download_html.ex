defmodule MehrSchulferienWeb.CalendarDownloadHTML do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "calendar_download"

  use PhoenixHTMLHelpers

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  import MehrSchulferienWeb.Shared.TypographyComponent
  import MehrSchulferienWeb.Shared.CardComponent

  import MehrSchulferienWeb.CalendarDownloadComponent,
    only: [download_path: 3, federal_state_pdf_path: 4, formats: 0]
end
