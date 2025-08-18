defmodule MehrSchulferienWeb.Api.V2.ICalICS do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "api/v2/i_cal"

  alias MehrSchulferien.Periods.CustomICal

  def render("icalendar.ics", %{location: location, periods: periods}) do
    CustomICal.generate(periods, location)
  end
end
