defmodule MehrSchulferien.Calendars.DateHelpers do
  @moduledoc """
  Date helper functions.
  """

  alias MehrSchulferien.Calendars.Day

  @leap_years [2020, 2024, 2028, 2032, 2036, 2040, 2044, 2048]
  @days_in_month %{
    1 => 31,
    2 => 28,
    3 => 31,
    4 => 30,
    5 => 31,
    6 => 30,
    7 => 31,
    8 => 31,
    9 => 30,
    10 => 31,
    11 => 30,
    12 => 31
  }
  @months %{
    1 => "Januar",
    2 => "Februar",
    3 => "März",
    4 => "April",
    5 => "Mai",
    6 => "Juni",
    7 => "Juli",
    8 => "August",
    9 => "September",
    10 => "Oktober",
    11 => "November",
    12 => "Dezember"
  }

  def create_year(year) do
    for month <- 1..12, do: create_month(year, month)
  end

  def create_month(year, month) do
    days_in_month = get_days_in_month(year, month)

    for day <- 1..days_in_month do
      Day.from_date(%Date{year: year, month: month, day: day, calendar: Calendar.ISO})
    end
  end

  def get_months_map, do: @months

  defp get_days_in_month(year, month) when month == 2 and year in @leap_years, do: 29
  defp get_days_in_month(_, month), do: @days_in_month[month]
end
