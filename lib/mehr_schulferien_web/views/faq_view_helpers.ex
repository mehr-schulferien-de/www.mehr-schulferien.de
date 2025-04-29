defmodule MehrSchulferienWeb.FaqViewHelpers do
  @moduledoc """
  Helper functions for use with views.
  """

  alias MehrSchulferien.{Calendars.DateHelpers, Periods}
  alias MehrSchulferienWeb.ViewHelpers

  @doc """
  An humanized answer if the given day is off school.
  """
  def is_off_school_answer(periods, date, location) do
    reasons =
      periods
      |> Enum.map(& &1.holiday_or_vacation_type.colloquial)
      |> ViewHelpers.comma_join_with_a_final_und()

    case Enum.count(periods) do
      0 ->
        "Nein, #{humanized_date(date)} #{ist_in_time(date)} nicht schulfrei in #{location.name}."

      _ ->
        "Ja, #{humanized_date(date)} #{ist_in_time(date)} schulfrei in #{location.name} (#{reasons})."
    end
  end

  @doc """
  An humanized answer if the given day is off school.
  """
  def is_public_holiday_answer(periods, date, location) do
    reasons =
      periods
      |> Enum.map(& &1.holiday_or_vacation_type.colloquial)
      |> ViewHelpers.comma_join_with_a_final_und()

    case Enum.count(periods) do
      0 ->
        "Nein, #{humanized_date(date)} #{ist_in_time(date)} kein gesetzlicher Feiertag in #{location.name}."

      _ ->
        "Ja, #{humanized_date(date)} #{ist_in_time(date)} ein gesetzlicher Feiertag in #{location.name} (#{reasons})."
    end
  end

  def day_distance_in_words(days) do
    case days do
      0 ->
        "Heute"

      1 ->
        "Morgen"

      2 ->
        "Übermorgen"

      7 ->
        "In einer Woche"

      14 ->
        "In zwei Wochen"

      21 ->
        "In drei Wochen"

      n when n < 14 ->
        "In #{n} Tagen"

      n ->
        case rem(n, 7) do
          0 ->
            "In #{round(n / 7)} Wochen (#{n} Tage)"

          _ ->
            weeks = trunc(n / 7)

            woche_word =
              case weeks do
                1 -> "Woche"
                _ -> "Wochen"
              end

            case n - weeks * 7 do
              1 -> "In #{n} Tagen (#{weeks} #{woche_word} und #{n - weeks * 7} Tag)"
              _ -> "In #{n} Tagen (#{weeks} #{woche_word} und #{n - weeks * 7} Tage)"
            end
        end
    end
  end

  @doc """
  An humanized answer for the next school vacations.
  """
  def next_school_vacation_answer(location, periods) do
    [period] = Periods.next_periods(periods, 1)

    if Date.diff(period.starts_on, DateHelpers.today_berlin()) > 0 do
      distance_in_words =
        day_distance_in_words(Date.diff(period.starts_on, DateHelpers.today_berlin()))

      "#{distance_in_words} starten die #{period.holiday_or_vacation_type.colloquial} in #{location.name}:
    #{ViewHelpers.format_date_range(period.starts_on, period.ends_on, nil)}"
    else
      "Aktuell sind #{period.holiday_or_vacation_type.colloquial} in #{location.name}: #{ViewHelpers.format_date_range(period.starts_on, period.ends_on, nil)}"
    end
  end

  def next_school_vacation(periods) do
    [period] = Periods.next_periods(periods, 1)
    period
  end

  @doc """
  An humanized answer for the next public holiday date.
  """
  def next_public_holiday_answer(location, public_periods) do
    [period] = Periods.next_periods(public_periods, 1)

    case Date.diff(period.starts_on, DateHelpers.today_berlin()) do
      1 ->
        "Morgen ist #{period.holiday_or_vacation_type.colloquial} in #{location.name}."

      n ->
        "In #{n} Tagen ist #{period.holiday_or_vacation_type.colloquial} in #{location.name}."
    end
  end

  @doc """
  ist is the German word for is. Depending on present or past it becomes war.
  """
  def ist_in_time(date) do
    if Date.diff(date, DateHelpers.today_berlin()) < 0 do
      "war"
    else
      "ist"
    end
  end

  @doc """
  Results in a more human way of telling the date. It adds
  vorgestern: the day before yesterday
  gestern: yesterday
  heute: today
  morgen: tomorrow
  übermorgen: the day after tomorrow
  """
  def humanized_date(date) do
    case Date.diff(date, DateHelpers.today_berlin()) do
      -2 -> "vorgestern (#{ViewHelpers.weekday(date)}, der #{ViewHelpers.format_date(date)})"
      -1 -> "gestern (#{ViewHelpers.weekday(date)}, der #{ViewHelpers.format_date(date)})"
      0 -> "heute (#{ViewHelpers.weekday(date)}, der #{ViewHelpers.format_date(date)})"
      1 -> "morgen (#{ViewHelpers.weekday(date)}, der #{ViewHelpers.format_date(date)})"
      2 -> "übermorgen (#{ViewHelpers.weekday(date)}, der #{ViewHelpers.format_date(date)})"
      _ -> "#{ViewHelpers.weekday(date)} der #{ViewHelpers.format_date(date)}"
    end
  end
end
