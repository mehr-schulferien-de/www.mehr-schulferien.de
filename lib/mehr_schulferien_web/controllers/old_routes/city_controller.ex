defmodule MehrSchulferienWeb.OldRoutes.CityController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Locations, Maps}

  def show(conn, %{"city_slug" => city_slug}) do
    country_slug = "d"
    <<zip_code_value::binary-size(5)>> <> "-" <> city_name = city_slug
    zip_code = Maps.get_zip_code_by_value!(zip_code_value)
    city_slug = find_city_slug(zip_code.locations, city_name)
    redirect(conn, to: Routes.city_path(conn, :show, country_slug, city_slug))
  end

  defp find_city_slug([], _), do: ""
  defp find_city_slug([location], _), do: location.slug

  defp find_city_slug(locations, city_name) do
    case Enum.find(locations, &(&1.slug == city_name)) do
      nil -> find_city_most_schools(locations).slug
      location -> location.slug
    end
  end

  defp find_city_most_schools(locations) do
    Enum.max_by(locations, &Locations.number_schools(&1))
  end
end
