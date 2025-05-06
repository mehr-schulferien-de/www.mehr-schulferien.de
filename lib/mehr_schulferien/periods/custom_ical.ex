defmodule MehrSchulferien.Periods.CustomICal do
  @moduledoc """
  A simple iCal generator that doesn't rely on Timex to avoid warnings.
  """

  alias MehrSchulferien.Periods.Period

  @doc """
  Generates iCal content for a list of periods and a location.
  """
  def generate(periods, location) do
    events = Enum.map(periods, &period_to_ical_event(&1, location))
    build_ical_content(events)
  end

  defp period_to_ical_event(
         %Period{
           ends_on: ends_on,
           holiday_or_vacation_type: holiday_or_vacation_type,
           starts_on: starts_on
         },
         location
       ) do
    # Format dates in iCal format (YYYYMMDD)
    start_date = format_date(starts_on)
    timestamp = generate_timestamp()

    """
    BEGIN:VEVENT
    CREATED:#{timestamp}Z
    DTEND;VALUE=DATE:#{add_day_and_format(ends_on)}
    DTSTAMP:#{timestamp}Z
    DTSTART;VALUE=DATE:#{start_date}
    LAST-MODIFIED:#{timestamp}Z
    SEQUENCE:1
    SUMMARY:#{escape_text(holiday_or_vacation_type.colloquial)} (#{escape_text(location.name)})
    TRANSP:TRANSPARENT
    UID:#{generate_uid()}
    DESCRIPTION:#{escape_text(holiday_or_vacation_type.name)}
    LOCATION:#{escape_text(location.name)}
    URL:https://www.mehr-schulferien.de/ferien/d/bundesland/#{location.slug}/#{starts_on.year}
    END:VEVENT
    """
  end

  defp build_ical_content(events) do
    """
    BEGIN:VCALENDAR
    CALSCALE:GREGORIAN
    VERSION:2.0
    #{Enum.join(events, "\n")}
    END:VCALENDAR
    """
  end

  # iCalendar date format: YYYYMMDD
  defp format_date(date) do
    "#{date.year}#{pad_number(date.month)}#{pad_number(date.day)}"
  end

  # In iCal, the end date is exclusive, so we need to add one day
  defp add_day_and_format(date) do
    date
    |> Date.add(1)
    |> format_date()
  end

  defp pad_number(number) when number < 10, do: "0#{number}"
  defp pad_number(number), do: "#{number}"

  # Generate timestamp in format YYYYMMDDTHHmmss
  defp generate_timestamp do
    datetime = DateTime.utc_now()

    "#{datetime.year}#{pad_number(datetime.month)}#{pad_number(datetime.day)}T#{pad_number(datetime.hour)}#{pad_number(datetime.minute)}#{pad_number(datetime.second)}"
  end

  # Generate a simple UUID for the event
  defp generate_uid do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16()
    |> then(fn string ->
      String.slice(string, 0, 8) <>
        "-" <>
        String.slice(string, 8, 4) <>
        "-" <>
        String.slice(string, 12, 4) <>
        "-" <>
        String.slice(string, 16, 4) <>
        "-" <>
        String.slice(string, 20, 12)
    end)
  end

  # Escape special characters according to iCal spec
  defp escape_text(text) do
    text
    |> String.replace("\\", "\\\\")
    |> String.replace(";", "\\;")
    |> String.replace(",", "\\,")
    |> String.replace("\n", "\\n")
  end
end
