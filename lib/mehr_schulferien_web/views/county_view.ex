defmodule MehrSchulferienWeb.CountyView do
  use MehrSchulferienWeb, :view

  def format_city_list([]), do: ""

  def format_city_list([first_city | cities]) do
    city_to_string(first_city) <> do_format(cities, "")
  end

  defp do_format([], string), do: string

  defp do_format([city], string) do
    string <> " und #{city_to_string(city)}"
  end

  defp do_format([city | rest], string) do
    string <> ", #{city_to_string(city)}" <> do_format(rest, string)
  end

  defp city_to_string(city) do
    "#{city.name} (#{Enum.map(city.zip_codes, & &1.value) |> Enum.sort() |> Enum.join(", ")})"
  end
end
