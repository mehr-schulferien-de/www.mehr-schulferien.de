defmodule MehrSchulferienWeb.WikiApprovalHTML do
  @moduledoc """
  HTML templates for wiki approval pages.
  """

  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "wiki_approval"

  use PhoenixHTMLHelpers

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  @doc """
  Formats a change type for display.
  """
  def format_change_type(change_type) do
    case change_type do
      "create_school" -> "Neue Schule anlegen"
      "update_school" -> "Schule bearbeiten"
      "delete_school" -> "Schule löschen"
      "create_period" -> "Neuen Ferientermin anlegen"
      "update_period" -> "Ferientermin bearbeiten"
      "delete_period" -> "Ferientermin löschen"
      "create_beweglicher_ferientag" -> "Neuen beweglichen Ferientag anlegen"
      "update_beweglicher_ferientag" -> "Beweglichen Ferientag bearbeiten"
      "delete_beweglicher_ferientag" -> "Beweglichen Ferientag löschen"
      _ -> change_type
    end
  end
end
