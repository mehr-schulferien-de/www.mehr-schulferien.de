defmodule MehrSchulferienWeb.CityComponents do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  alias MehrSchulferienWeb.Shared.SchemaOrgComponent

  def schema_org_event(assigns) do
    assigns =
      assign(assigns, :place, %{
        name: assigns.city.name,
        street: "",
        locality: assigns.city.name,
        zip: "",
        region: assigns.federal_state.name,
        country: assigns.country.code
      })

    SchemaOrgComponent.schema_org_event(assigns)
  end
end
