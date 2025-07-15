defmodule MehrSchulferienWeb.Helpers.DateCalculations do
  @moduledoc """
  Common date calculation helpers to avoid duplication across templates and components.
  """

  @doc """
  Calculate surrounding dates (yesterday, today, tomorrow, day after tomorrow)
  from a given date.
  """
  def calculate_surrounding_dates(today) do
    %{
      yesterday: Date.add(today, -1),
      today: today,
      tomorrow: Date.add(today, 1),
      day_after_tomorrow: Date.add(today, 2)
    }
  end

  @doc """
  Get date range for FAQ data calculations.
  Returns a tuple of {start_date, end_date}.
  """
  def faq_date_range(today) do
    {Date.add(today, -1), Date.add(today, 2)}
  end
end
