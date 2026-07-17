defmodule MehrSchulferienWeb.Helpers.MonthHelpers do
  @moduledoc """
  Month name helpers for templates. Thin wrapper around the canonical month
  names in `MehrSchulferien.Calendars.DateHelpers`.
  """

  alias MehrSchulferien.Calendars.DateHelpers

  @doc """
  Get the German month name for a given month number (1-12).
  """
  def month_name(month_number) when month_number in 1..12 do
    DateHelpers.get_months_map()[month_number]
  end

  @doc """
  Get all months as a map.
  """
  def months_map, do: DateHelpers.get_months_map()

  @doc """
  Get month name from a Date struct.
  """
  def month_name_from_date(%Date{month: month}) do
    month_name(month)
  end
end
