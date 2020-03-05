defmodule MehrSchulferienWeb.CountyView do
  use MehrSchulferienWeb, :view

  def format_zip_codes(city) do
    "#{Enum.map(city.zip_codes, & &1.value) |> Enum.sort() |> Enum.join(", ")}"
  end
end
