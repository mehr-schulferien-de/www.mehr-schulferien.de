defmodule MehrSchulferienWeb.PageView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferien.{Calendars, Locations}

  def number_schools() do
    Locations.number_schools()
  end

  def get_days_period(date, periods) do
    case Calendars.find_all_periods(periods, date) do
      [] -> nil
      [period] -> period
      periods -> periods |> Enum.sort(&(&1.display_priority >= &2.display_priority)) |> hd
    end
  end

  def display_period_info?(date, dates, period) do
    if date == hd(dates) do
      true
    else
      period.is_school_vacation == true && date == period.starts_on
    end
  end

  def get_period_colspan(date, period) do
    Date.diff(period.ends_on, date) + 1
  end

  def show_period_info(period, colspan) when colspan < 10 do
    show_period_name(period)
  end

  def show_period_info(period, _) do
    show_period_name(period) <> " " <> show_period_date(period)
  end

  defp show_period_name(period) do
    "#{period.holiday_or_vacation_type.colloquial}"
  end

  defp show_period_date(period) do
    "(#{ViewHelpers.format_date_range(period.starts_on, period.ends_on, :short)})"
  end
end
