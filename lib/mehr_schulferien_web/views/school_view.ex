defmodule MehrSchulferienWeb.SchoolView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferienWeb.{ViewHelpers}

  # Import the components we need for our templates
  import MehrSchulferienWeb.School.PaginationComponent
  import MehrSchulferienWeb.School.PeriodsTableComponent
  import MehrSchulferienWeb.FederalState.CalendarLegendComponent
  import MehrSchulferienWeb.FederalState.MonthCalendarComponent
  import MehrSchulferienWeb.SchoolComponents
  import MehrSchulferienWeb.FaqComponent
  import MehrSchulferienWeb.Shared.IcalPanelComponent

  def calculate_effective_duration(period, periods) do
    # Get official duration
    official_duration = Date.diff(period.ends_on, period.starts_on) + 1

    # Look for adjacent days that are already off days
    # These could be weekends or other holiday periods

    # Check days before the period start
    days_before =
      get_adjacent_days_before(period.starts_on, periods)
      |> length()

    # Check days after the period end
    days_after =
      get_adjacent_days_after(period.ends_on, periods)
      |> length()

    # Return total effective duration
    official_duration + days_before + days_after
  end

  # Get days before a date that are already non-school days
  defp get_adjacent_days_before(start_date, periods) do
    # Start checking from the day before the period
    day_before = Date.add(start_date, -1)

    # Look back up to 7 days (to catch full weekends + holidays)
    dates_to_check = for i <- 0..6, do: Date.add(day_before, -i)

    # Keep only consecutive days off
    Enum.take_while(dates_to_check, fn date ->
      # A date is a day off if:
      # 1. It's a weekend (Sat/Sun)
      # 2. It's part of another period (holiday/vacation)
      is_weekend_or_holiday?(date, periods)
    end)
  end

  # Get days after a date that are already non-school days
  defp get_adjacent_days_after(end_date, periods) do
    # Start checking from the day after the period
    day_after = Date.add(end_date, 1)

    # Look ahead up to 7 days (to catch full weekends + holidays)
    dates_to_check = for i <- 0..6, do: Date.add(day_after, i)

    # Keep only consecutive days off
    Enum.take_while(dates_to_check, fn date ->
      # A date is a day off if:
      # 1. It's a weekend (Sat/Sun)
      # 2. It's part of another period (holiday/vacation)
      is_weekend_or_holiday?(date, periods)
    end)
  end

  # Check if a date is a weekend or part of any holiday period
  defp is_weekend_or_holiday?(date, periods) do
    day_of_week = Date.day_of_week(date)
    is_weekend = day_of_week == 6 || day_of_week == 7

    if is_weekend do
      true
    else
      # Check if this date is part of another holiday period
      Enum.any?(periods, fn period ->
        Date.compare(date, period.starts_on) != :lt && Date.compare(date, period.ends_on) != :gt
      end)
    end
  end

  def format_date_range(period, short_format \\ false) do
    ViewHelpers.format_date_range(period.starts_on, period.ends_on, if(short_format, do: :short))
  end

  def format_weekday_and_date(date, short_format \\ false) do
    weekday = ViewHelpers.weekday(date)
    date_string = ViewHelpers.format_date(date, if(short_format, do: :short))
    "#{weekday}, #{date_string}"
  end

  def period_collection_for_year_table(school_periods, public_periods, year) do
    # Collect all periods for display in a year overview
    all_periods = school_periods ++ public_periods
    public_holiday_periods = Enum.filter(public_periods, & &1.is_public_holiday)

    # Add some period data per month and store in a map
    months =
      1..12
      |> Enum.map(fn month ->
        periods_for_month = periods_by_month(all_periods, month, year)
        public_holiday_periods_for_month = periods_by_month(public_holiday_periods, month, year)

        {month,
         %{
           month_name: short_month_name(month),
           periods: periods_for_month,
           public_holiday_periods: public_holiday_periods_for_month
         }}
      end)
      |> Map.new()

    %{months: months}
  end

  def period_style_for_year_table(period) do
    cond do
      period.holiday_or_vacation_type.name == "Wochenende" -> "bg-gray-300"
      period.is_public_holiday -> "bg-red-200"
      true -> "bg-green-200"
    end
  end

  def periods_for_date_range(periods, start_date, end_date) do
    Enum.filter(periods, fn period ->
      date_range_overlaps?(period.starts_on, period.ends_on, start_date, end_date)
    end)
  end

  def periods_by_month(periods, month_number, year) do
    {:ok, first_day} = Date.new(year, month_number, 1)
    month_days = days_in_month(first_day)
    {:ok, last_day} = Date.new(year, month_number, month_days)

    periods_for_date_range(periods, first_day, last_day)
  end

  # Helper to get the number of days in a month
  defp days_in_month(%Date{year: year, month: month}) do
    # Implementation matches DateHelpers.days_in_month
    Date.days_in_month(Date.new!(year, month, 1))
  end

  def short_month_name(month_number) do
    months = %{
      1 => "Jan",
      2 => "Feb",
      3 => "Mär",
      4 => "Apr",
      5 => "Mai",
      6 => "Jun",
      7 => "Jul",
      8 => "Aug",
      9 => "Sep",
      10 => "Okt",
      11 => "Nov",
      12 => "Dez"
    }

    Map.get(months, month_number, "")
  end

  # Helper function to check if two date ranges overlap
  defp date_range_overlaps?(start_a, end_a, start_b, end_b) do
    Date.compare(start_a, end_b) != :gt && Date.compare(end_a, start_b) != :lt
  end
end
