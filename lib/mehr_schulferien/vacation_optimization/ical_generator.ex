defmodule MehrSchulferien.VacationOptimization.ICalGenerator do
  @moduledoc """
  Generates iCal files for optimal vacation windows.
  """

  alias MehrSchulferien.VacationOptimization.Result

  @doc """
  Generates iCal content for a list of optimal vacation windows.
  """
  def generate(optimal_windows, federal_state, year, days) do
    events = Enum.map(optimal_windows, &window_to_ical_event(&1, federal_state, days))
    build_ical_content(events, federal_state, year, days)
  end

  defp window_to_ical_event(
         %Result{
           rank: rank,
           start_date: start_date,
           end_date: end_date,
           vacation_days_used: vacation_days,
           total_free_days: total_free_days,
           efficiency_percentage: efficiency_pct,
           related_holidays: related_holidays
         },
         federal_state,
         days
       ) do
    timestamp = generate_timestamp()

    description =
      build_description(vacation_days, total_free_days, efficiency_pct, related_holidays)

    """
    BEGIN:VEVENT
    CREATED:#{timestamp}Z
    DTEND;VALUE=DATE:#{add_day_and_format(end_date)}
    DTSTAMP:#{timestamp}Z
    DTSTART;VALUE=DATE:#{format_date(start_date)}
    LAST-MODIFIED:#{timestamp}Z
    SEQUENCE:1
    SUMMARY:Optimaler Urlaub (Rang #{rank}) - #{total_free_days} Tage
    DESCRIPTION:#{escape_text(description)}
    TRANSP:TRANSPARENT
    UID:#{generate_uid()}
    LOCATION:#{escape_text(federal_state.name)}
    CATEGORIES:URLAUB,OPTIMIERT
    URL:https://www.mehr-schulferien.de/urlaubsplaner/#{federal_state.slug}/#{days}-tage/#{start_date.year}
    END:VEVENT
    """
  end

  defp build_description(vacation_days, total_free_days, efficiency_pct, related_holidays) do
    holidays_text =
      if related_holidays && length(related_holidays) > 0 do
        "\\nEnthält: #{Enum.join(related_holidays, ", ")}"
      else
        ""
      end

    "#{vacation_days} Urlaubstage → #{total_free_days} freie Tage (#{efficiency_pct}% Effizienz)#{holidays_text}\\nBerechnet von mehr-schulferien.de"
  end

  defp build_ical_content(events, federal_state, year, days) do
    """
    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//mehr-schulferien.de//Urlaubsplaner//DE
    CALSCALE:GREGORIAN
    X-WR-CALNAME:Urlaubsplaner #{federal_state.name} #{year} (#{days} Tage)
    #{Enum.join(events, "\n")}
    END:VCALENDAR
    """
  end

  defp format_date(date) do
    "#{date.year}#{pad_number(date.month)}#{pad_number(date.day)}"
  end

  defp add_day_and_format(date) do
    date
    |> Date.add(1)
    |> format_date()
  end

  defp pad_number(number) when number < 10, do: "0#{number}"
  defp pad_number(number), do: "#{number}"

  defp generate_timestamp do
    datetime = DateTime.utc_now()

    "#{datetime.year}#{pad_number(datetime.month)}#{pad_number(datetime.day)}T#{pad_number(datetime.hour)}#{pad_number(datetime.minute)}#{pad_number(datetime.second)}"
  end

  defp generate_uid do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
    |> then(&"#{&1}@mehr-schulferien.de")
  end

  defp escape_text(text) when is_binary(text) do
    text
    |> String.replace("\\", "\\\\")
    |> String.replace(",", "\\,")
    |> String.replace(";", "\\;")
    |> String.replace("\n", "\\n")
  end

  defp escape_text(nil), do: ""
end
