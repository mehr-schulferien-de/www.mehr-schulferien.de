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
    only: [download_path: 3, federal_state_pdf_path: 4]

  @doc "The formats with the name and the use shown on their card."
  def formats do
    [
      {"a3", "DIN A3",
       "Wandkalender im Querformat, 420 × 297 mm. Für Kopierer und Drucker mit A3-Fach."},
      {"a4", "DIN A4",
       "Die Jahresübersicht im Querformat, mit Ferien- und Feiertagsnamen in den Tagen. Passt auf jeden Drucker."},
      {"a5", "DIN A5", "Kompakte Jahresübersicht für Hausaufgabenheft und Planer."},
      {"karte", "Kreditkartenformat",
       "Vier Karten auf einem A4-Blatt, je 85,6 × 54 mm, mit Schnittmarken. Ausschneiden, falten, ins Portemonnaie stecken."}
    ]
  end
end
