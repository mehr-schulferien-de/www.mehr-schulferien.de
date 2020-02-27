defmodule MehrSchulferienWeb.ViewHelpers do
  @moduledoc """
  Helper functions for use with views.
  """

  alias MehrSchulferien.Calendars

  @doc """
  Returns the number of days a holiday period lasts for.
  """
  def number_days([period]) do
    Date.diff(period.ends_on, period.starts_on) + 1
  end

  def number_days(periods) do
    Enum.reduce(periods, 0, fn period, acc ->
      Date.diff(period.ends_on, period.starts_on) + 1 + acc
    end)
  end

  @doc """
  Returns a string showing the date range in DD.MM. or DD.MM.YY format.

  If the from_date and till_date are the same, then just a single date is
  returned.
  """
  def format_date_range(from_date, till_date, short \\ nil)

  def format_date_range(same_date, same_date, short) do
    format_date(same_date, short)
  end

  def format_date_range(from_date, till_date, short) do
    format_date(from_date, short) <> " - " <> format_date(till_date, short)
  end

  defp format_date(date, nil) do
    format_date(date, :short) <> "#{date.year |> Integer.to_string() |> String.slice(2, 2)}"
  end

  defp format_date(date, :short) do
    "#{add_padding(date.day)}.#{add_padding(date.month)}."
  end

  defp add_padding(entry) do
    entry |> Integer.to_string() |> String.pad_leading(2, "0")
  end

  @doc """
  Returns the year based on the `starts_on` value in the first non-empty period.
  """
  def display_year([[] | rest]), do: display_year(rest)
  def display_year([[period | _] | _]), do: period.starts_on.year

  @doc """
  Returns the html class based on whether the date is a public holiday,
  a school holiday or a weekend.
  """
  def get_html_class(date, day_of_week, public_periods, school_periods) do
    public = Calendars.find_period(date, public_periods)
    school = Calendars.find_period(date, school_periods)

    case {public, school} do
      {nil, nil} -> get_html_class(day_of_week)
      {nil, period} -> period.html_class
      {period, nil} -> period.html_class
      {public_period, school_period} -> select_html_class(public_period, school_period)
    end
  end

  @doc """
  Returns the html class based on whether the date is a holiday or weekend.
  """
  def get_html_class(date, day_of_week, periods) do
    case Calendars.find_period(date, periods) do
      nil -> get_html_class(day_of_week)
      period -> period.html_class
    end
  end

  defp get_html_class(day_of_week) when day_of_week > 5, do: "active"
  defp get_html_class(_), do: ""

  defp select_html_class(period_1, period_2) do
    if period_1.display_priority >= period_2.display_priority do
      period_1.html_class
    else
      period_2.html_class
    end
  end

  @doc """
  Returns the public holiday periods and school holiday periods for a month.
  """
  def get_month_holidays(month, public_periods, school_periods) do
    {get_month_holidays(month, public_periods), get_month_holidays(month, school_periods)}
  end

  @doc """
  Returns the holiday periods for a month.
  """
  def get_month_holidays(month, periods) do
    month
    |> Calendars.find_periods_by_month(periods)
    |> Enum.chunk_by(& &1.holiday_or_vacation_type.name)
  end
end
