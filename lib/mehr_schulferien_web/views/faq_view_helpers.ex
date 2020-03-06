defmodule MehrSchulferienWeb.FaqViewHelpers do
  @moduledoc """
  Helper functions for use with views.
  """
  alias MehrSchulferien.Calendars
  alias MehrSchulferienWeb.ViewHelpers

  @doc """
  An humanized answer if the given day is off school.
  """
  def is_off_school_answer(periods, date, location) do
    reasons =
      Enum.map(periods, fn x -> x.holiday_or_vacation_type.name end)
      |> ViewHelpers.comma_join_with_a_final_und

    case Enum.count(periods) do
      0 ->
        "Nein, #{humanized_date(date)} #{ist_in_time(date)} nicht schulfrei in #{location.name}."

      1 ->
        "Ja, #{humanized_date(date)} #{ist_in_time(date)} schulfrei in #{location.name}. " <>
          "An diesem Tag ist #{reasons}."

      _ ->
        "Ja, #{humanized_date(date)} #{ist_in_time(date)} schulfrei in #{location.name}. An diesem Tag #{ist_in_time(date)} #{
          reasons
        }."
    end
  end

  def ist_in_time(date) do
    if Date.diff(date, Date.utc_today) < 0 do
      "war"
    else
      "ist"
    end
  end

  def humanized_date(date) do
    case Date.diff(date, Date.utc_today()) do
      -2 -> "vorgestern (#{ViewHelpers.weekday(date)}, der #{ViewHelpers.format_date(date)})"
      -1 -> "gestern (#{ViewHelpers.weekday(date)}, der #{ViewHelpers.format_date(date)})"
      0 -> "heute (#{ViewHelpers.weekday(date)}, der #{ViewHelpers.format_date(date)})"
      1 -> "morgen (#{ViewHelpers.weekday(date)}, der #{ViewHelpers.format_date(date)})"
      2 -> "übermorgen (#{ViewHelpers.weekday(date)}, der #{ViewHelpers.format_date(date)})"
      _ -> "#{ViewHelpers.weekday(date)} der #{ViewHelpers.format_date(date)}"
    end
  end

end
