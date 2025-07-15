defmodule MehrSchulferienWeb.Helpers.MonthHelpers do
  @moduledoc """
  Month name constants and helpers to avoid hardcoding throughout the application.
  """

  @months_map %{
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
  Get the German month name for a given month number (1-12).
  """
  def month_name(month_number) when month_number in 1..12 do
    @months_map[month_number]
  end

  @doc """
  Get all months as a map.
  """
  def months_map, do: @months_map

  @doc """
  Get month name from a Date struct.
  """
  def month_name_from_date(%Date{month: month}) do
    month_name(month)
  end
end
