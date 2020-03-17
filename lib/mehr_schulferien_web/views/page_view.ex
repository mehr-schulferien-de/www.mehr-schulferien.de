defmodule MehrSchulferienWeb.PageView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferien.Locations

  def number_schools() do
    Locations.number_schools()
  end
end
