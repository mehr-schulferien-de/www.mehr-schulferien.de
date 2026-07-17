defmodule MehrSchulferienWeb.FederalStateComponents do
  use Phoenix.Component

  alias MehrSchulferienWeb.Shared.SchemaOrgComponent

  def schema_org_event(assigns) do
    assigns =
      assign(assigns, :place, %{
        name: assigns.federal_state.name,
        street: "",
        locality: "",
        zip: "",
        region: assigns.federal_state.name,
        country: assigns.country.code
      })

    SchemaOrgComponent.schema_org_event(assigns)
  end
end
