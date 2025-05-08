defmodule MehrSchulferienWeb.Old.CityView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferien.Locations

  def count_schools(city) do
    Locations.count_schools(city)
  end

  def format_zip_codes(city) do
    joined_zip_codes =
      "#{Enum.map(city.zip_codes, & &1.value) |> Enum.sort() |> truncate()}"

    case Enum.count(city.zip_codes) do
      0 -> ""
      1 -> "(Postleitzahl #{joined_zip_codes})"
      _ -> "(Postleitzahlen #{joined_zip_codes})"
    end
  end

  defp truncate(zip_codes) do
    case Enum.count(zip_codes) do
      0 ->
        ""

      1 ->
        "#{hd(zip_codes)}"

      x when x > 5 ->
        "#{hd(zip_codes)} - #{List.last(zip_codes)}"

      _ ->
        first_elements = zip_codes |> Enum.reverse() |> tl() |> Enum.reverse()
        last_element = zip_codes |> Enum.reverse() |> hd()
        "#{Enum.join(first_elements, ", ")} und #{last_element}"
    end
  end
end
