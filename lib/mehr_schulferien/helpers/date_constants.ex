defmodule MehrSchulferien.Helpers.DateConstants do
  @moduledoc """
  Constants for date calculations to avoid magic numbers throughout the codebase.
  """

  # Number of days in a year (non-leap)
  @days_per_year 365

  # Approximate number of days in a month (used for rough calculations)
  @days_per_month 30

  # Number of months in a year
  @months_per_year 12

  # Number of days in a week
  @days_per_week 7

  def days_per_year, do: @days_per_year
  def days_per_month, do: @days_per_month
  def months_per_year, do: @months_per_year
  def days_per_week, do: @days_per_week

  @doc """
  Calculates date offset in days from a given number of months.
  Uses approximate month length (30 days).
  """
  def days_from_months(months) when is_integer(months) do
    months * @days_per_month
  end

  @doc """
  Calculates date offset in days from a given number of years.
  Uses standard year length (365 days).
  """
  def days_from_years(years) when is_integer(years) do
    years * @days_per_year
  end
end
