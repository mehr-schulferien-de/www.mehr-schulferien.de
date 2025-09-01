defmodule MehrSchulferienWeb.Api.V2.LocationJSON do
  def index(%{locations: locations}) do
    %{data: for(location <- locations, do: data(location))}
  end

  def show(%{location: location}) do
    %{data: data(location)}
  end

  defp data(location) do
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
