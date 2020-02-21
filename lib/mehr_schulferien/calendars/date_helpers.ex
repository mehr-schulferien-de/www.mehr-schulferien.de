defmodule MehrSchulferien.Calendars.DateHelpers do
  @moduledoc """
  Date helper functions.
  """

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

  @doc """
  Returns 3 years of dates.
  """
  def create_3_years(year) do
    create_year(year) ++ create_year(year + 1) ++ create_year(year + 2)
  end

  @doc """
  Returns a list of lists of dates for a certain year.
  """
  def create_year(year) do
    for month <- 1..12, do: create_month(year, month)
  end

  @doc """
  Returns a list of dates for a certain month.
  """
  def create_month(year, month) do
    days_in_month = get_days_in_month(year, month)

    for day <- 1..days_in_month do
      %Date{year: year, month: month, day: day, calendar: Calendar.ISO}
    end
  end

  @doc """
  Returns a map containing the month numbers as keys and the month German
  names as values.
  """
  def get_months_map, do: @months

  defp get_days_in_month(year, month) when month == 2 and year in @leap_years, do: 29
  defp get_days_in_month(_, month), do: @days_in_month[month]

  @doc """
  Compares two days by comparing just month and year.

  Returns :gt, :eq or :lt - like Date.compare/2.
  """
  def compare_by_month(%Date{month: month, year: year}, %Date{month: month, year: year}) do
    :eq
  end

  def compare_by_month(%Date{month: month_1, year: year}, %Date{month: month_2, year: year}) do
    if month_1 > month_2, do: :gt, else: :lt
  end

  def compare_by_month(%Date{year: year_1}, %Date{year: year_2}) do
    if year_1 > year_2, do: :gt, else: :lt
  end
end
