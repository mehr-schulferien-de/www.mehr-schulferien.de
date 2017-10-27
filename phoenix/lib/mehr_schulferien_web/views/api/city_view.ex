defmodule MehrSchulferienWeb.Api.CityView do
  use MehrSchulferienWeb, :view
  alias MehrSchulferienWeb.Api.CityView

  def render("index.json", %{cities: cities}) do
    %{data: render_many(cities, CityView, "city.json")}
  end

  def render("show.json", %{city: city}) do
    %{data: render_one(city, CityView, "city.json")}
  end

  def render("city.json", %{city: city}) do
    %{id: city.id,
      name: city.name,
      slug: city.slug,
      zip_code: city.zip_code,
      country_id: city.country_id,
      federal_state_id: city.federal_state_id}
  end
end
