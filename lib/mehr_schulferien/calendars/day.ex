defmodule MehrSchulferien.Calendars.Day do
  @moduledoc """
  Day (date) struct and helper functions.
  """

  # NOTE: riverrun (2020-02-19)
  # This struct might not be needed. We could use Date structs instead.
  #
  # However, this Day struct could be especially useful if we want to
  # generate the template days / dates in advance.

  defstruct date: nil,
            display: "",
            day_of_week: nil,
            day: nil,
            month: nil,
            year: nil,
            html_class: ""

  def from_date(%Date{day: day, month: month, year: year} = date) do
    day_of_week = Date.day_of_week(date)

    %__MODULE__{
      date: date,
      display: "#{day}.",
      day_of_week: day_of_week,
      day: day,
      month: month,
      year: year,
      html_class: get_html_class(day_of_week)
    }
  end

  defp get_html_class(day_of_week) when day_of_week > 5 do
    "active"
  end

  defp get_html_class(_), do: ""
end
