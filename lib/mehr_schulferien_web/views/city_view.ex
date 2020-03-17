defmodule MehrSchulferienWeb.CityView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferien.Locations

  def number_schools(city) do
    Locations.number_schools(city)
  end

  def format_zip_codes(city) do
    "(PLZ #{
      Enum.map(city.zip_codes, & &1.value)
      |> Enum.sort()
      |> truncate()
    })"
  end

  defp truncate(zip_codes) do
    if length(zip_codes) > 5 do
      "#{hd(zip_codes)}..#{List.last(zip_codes)}"
    else
      Enum.join(zip_codes, ", ")
    end
  end
end
