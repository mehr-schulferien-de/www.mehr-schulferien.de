defmodule MehrSchulferienWeb.OldRoutes.CityController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Maps

  def show(conn, %{"city_slug" => city_slug}) do
    country_slug = "d"
    <<zip_code_value::binary-size(5)>> <> _ = city_slug
    zip_code = Maps.get_zip_code_by_value!(zip_code_value)
    city_slug = find_city_slug(zip_code.locations)
    redirect(conn, to: Routes.city_path(conn, :show, country_slug, city_slug))
  end

  defp find_city_slug([first | _]) do
    first.slug
  end
end
