defmodule MehrSchulferien.Periods.ICal do
  @moduledoc """
  Module to generate ICalendar files.
  """

  alias MehrSchulferien.Periods.Period

  def period_to_event(
        %Period{
          ends_on: ends_on,
          holiday_or_vacation_type: holiday_or_vacation_type,
          starts_on: starts_on
        },
        location
      ) do
    %ICalendar.Event{
      summary: holiday_or_vacation_type.colloquial,
      dtstart: {Date.to_erl(starts_on), {0, 0, 00}},
      dtend: {Date.to_erl(ends_on), {23, 59, 59}},
      description: holiday_or_vacation_type.name,
      location: location.name
    }
  end

  def write_icalendar(%ICalendar{} = icalendar, name) do
    File.write!("#{name}.ics", ICalendar.to_ics(icalendar))
  end
end
