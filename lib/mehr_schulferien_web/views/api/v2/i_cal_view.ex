defmodule MehrSchulferienWeb.Api.V2.ICalView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferien.Periods.CustomICal

  def render("icalendar.ics", %{location: location, periods: periods}) do
    CustomICal.generate(periods, location)
  end
end
