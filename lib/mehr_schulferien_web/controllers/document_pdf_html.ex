defmodule MehrSchulferienWeb.DocumentPdfHTML do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "document_pdf"

  # PDF controller sends binary data directly - no templates used
end
