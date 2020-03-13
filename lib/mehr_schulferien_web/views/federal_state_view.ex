defmodule MehrSchulferienWeb.FederalStateView do
  use MehrSchulferienWeb, :view

  def format_zip_codes(city) do
    "#{
      Enum.map(city.zip_codes, & &1.value)
      |> Enum.sort()
      |> MehrSchulferienWeb.ViewHelpers.comma_join_with_a_final_und()
    }"
  end
end
