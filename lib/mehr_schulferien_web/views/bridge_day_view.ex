defmodule MehrSchulferienWeb.BridgeDayView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferien.Calendars.DateHelpers

  def format_month_header(start_date, end_date) do
    months_map = DateHelpers.get_months_map()
    first_month = start_date.month
    last_month = end_date.month

    if first_month == last_month do
      months_map[first_month]
    else
      "#{String.slice(months_map[first_month], 0, 3)}-#{
        String.slice(months_map[last_month], 0, 3)
      }"
    end
  end

  def get_number_max_days(periods) do
    start_date = hd(periods).starts_on
    end_date = List.last(periods).ends_on
    Date.diff(end_date, start_date) + 1
  end

  # NOTE: riverrun (2020-05-27)
  # This function is not being used because if a public holiday overlaps
  # with a weekend day, it is counted as a weekend day (and not a public
  # holiday) in the bridge day panel.
  def get_number_public_holidays(periods) do
    periods
    |> Enum.filter(& &1.is_public_holiday)
    |> calculate_number_days()
  end

  def get_number_weekend_days(periods) do
    periods
    |> Enum.filter(&(&1.holiday_or_vacation_type.name == "Wochenende"))
    |> calculate_number_days()
  end

  defp calculate_number_days(periods) do
    Enum.reduce(periods, 0, fn period, acc ->
      acc + Date.diff(period.ends_on, period.starts_on) + 1
    end)
  end
end
