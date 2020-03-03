defmodule MehrSchulferienWeb.CountyViewTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Maps
  alias MehrSchulferienWeb.CountyView

  test "format_city_list/1 formats a list of cities" do
    county = insert(:county)
    insert_list(3, :city, %{parent_location_id: county.id})
    cities = Maps.list_cities(county)
    assert CountyView.format_city_list(cities)
  end

  test "format_city_list/1 returns an empty string if list is empty" do
    assert CountyView.format_city_list([]) == ""
  end
end
