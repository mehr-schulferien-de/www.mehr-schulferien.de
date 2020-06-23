defmodule MehrSchulferienWeb.Api.V2.ICalView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferien.Periods.ICal

  def render("icalendar.ics", %{location: location, periods: periods}) do
    periods |> generate_icalendar(location) |> ICalendar.to_ics()
  end

  defp generate_icalendar(periods, location) do
    %ICalendar{events: Enum.map(periods, &ICal.period_to_event(&1, location))}
  end
end
