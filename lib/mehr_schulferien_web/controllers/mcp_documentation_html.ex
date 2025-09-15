defmodule MehrSchulferienWeb.MCPDocumentationHTML do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "mcp_documentation"

  # Basic view imports
  use PhoenixHTMLHelpers

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router
end
