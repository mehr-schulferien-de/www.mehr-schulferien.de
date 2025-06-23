defmodule MehrSchulferienWeb.SchoolView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferienWeb.{ViewHelpers}

  # Import the components we need for our templates
  import MehrSchulferienWeb.Shared.GenericPaginationComponent
  import MehrSchulferienWeb.School.PeriodsTableComponent
  import MehrSchulferienWeb.FederalState.CalendarLegendComponent
  import MehrSchulferienWeb.FederalState.MonthCalendarComponent
  import MehrSchulferienWeb.SchoolComponents
  import MehrSchulferienWeb.FaqComponent
  import MehrSchulferienWeb.ICalPanelComponent

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
