defmodule MehrSchulferienWeb.SchoolView do
  use MehrSchulferienWeb, :view

  def truncate(string) do
    if String.length(string) > 28 do
      ~E"""
      <abbr title="<%= string %>"><%= snip(string) %></abbr>
      """
    else
      string
    end
  end

  defp snip(string) do
    string =
      string
      |> String.slice(0..24)

    string <> "..."
  end
end
