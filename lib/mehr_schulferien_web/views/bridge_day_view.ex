defmodule MehrSchulferienWeb.BridgeDayView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferien.Calendars.DateHelpers

  def format_month_header(start_date, end_date) do
    months_map = DateHelpers.get_months_map()
    first_month = start_date.month
    last_month = end_date.month
    first_year = start_date.year
    last_year = end_date.year

    cond do
      # Same month
      first_month == last_month ->
        months_map[first_month]

      # Multiple months, different years
      first_year != last_year ->
        first_month_abbr = String.at(months_map[first_month], 0) <> "."
        "#{first_month_abbr} #{first_year} #{months_map[last_month]} #{last_year}"

      # Multiple months, same year (use abbreviated format for first month)
      true ->
        first_month_abbr = String.at(months_map[first_month], 0) <> "."
        "#{first_month_abbr} #{months_map[last_month]}"
    end
  end

  def get_number_max_days(periods) do
    start_date = hd(periods).starts_on
    end_date = List.last(periods).ends_on
    Date.diff(end_date, start_date) + 1
  end

  @doc """
  Checks if a bridge day meets the minimum gain requirements:
  - 1 day off → at least 3 free days (more reasonable)
  - 2 days off → at least 4 free days
  - 3 days off → at least 5 free days
  - 4 days off → at least 6 free days

  Returns true if the bridge day meets the minimum gain requirements, false otherwise.
  """
  def meets_minimum_gain?(bridge_day, periods) do
    vacation_days = bridge_day.number_days
    total_free_days = get_number_max_days(periods)

    minimum_free_days =
      case vacation_days do
        # 1 day off → at least 3 free days (more reasonable)
        1 -> 3
        # 2 days off → at least 4 free days
        2 -> 4
        # 3 days off → at least 5 free days
        3 -> 5
        # 4 days off → at least 6 free days
        4 -> 6
        # Fallback for other values
        _ -> vacation_days + 2
      end

    total_free_days >= minimum_free_days
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

  def get_reference_date(conn) do
    DateHelpers.get_today_or_custom_date(conn)
  end
end
