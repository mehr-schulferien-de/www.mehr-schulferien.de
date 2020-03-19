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
    string
    |> String.slice(0..27)
  end
end
