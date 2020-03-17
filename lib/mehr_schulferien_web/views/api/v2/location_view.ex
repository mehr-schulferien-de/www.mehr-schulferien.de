defmodule MehrSchulferienWeb.Api.V2.LocationView do
  use MehrSchulferienWeb, :view

  def render("index.json", %{locations: locations}) do
    %{data: render_many(locations, __MODULE__, "location.json")}
  end

  def render("show.json", %{location: location}) do
    %{data: render_one(location, __MODULE__, "location.json")}
  end

  def render("location.json", %{location: location}) do
    %{
      id: location.id,
      name: location.name,
      code: location.code,
      is_country: location.is_country,
      is_federal_state: location.is_federal_state,
      is_county: location.is_county,
      is_city: location.is_city,
      is_school: location.is_school,
      parent_location_id: location.parent_location_id,
      updated_at: location.updated_at
    }
  end
end
