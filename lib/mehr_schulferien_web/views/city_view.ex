defmodule MehrSchulferienWeb.CityView do
  use MehrSchulferienWeb, :view

  # Import the components we need for our templates
  import MehrSchulferienWeb.City.PaginationComponent
  import MehrSchulferienWeb.FederalState.PeriodsTableComponent
  import MehrSchulferienWeb.FederalState.CalendarLegendComponent
  import MehrSchulferienWeb.FederalState.MonthCalendarComponent
  import MehrSchulferienWeb.FederalState.NoDataComponent
  import MehrSchulferienWeb.FederalState.PartialDataComponent
  import MehrSchulferienWeb.CityComponents
  import MehrSchulferienWeb.FaqComponent
  import MehrSchulferienWeb.Shared.IcalPanelComponent

  def format_zip_codes(city) do
    "#{Enum.map(city.zip_codes, & &1.value) |> Enum.sort() |> MehrSchulferienWeb.ViewHelpers.comma_join_with_a_final_und()}"
  end

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
    # Weekend check (day_of_week: 6=Saturday, 7=Sunday)
    is_weekend = Date.day_of_week(date) > 5

    # Holiday check - is this date within any period?
    is_holiday =
      Enum.any?(periods, fn p ->
        Date.compare(date, p.starts_on) in [:eq, :gt] &&
          Date.compare(date, p.ends_on) in [:lt, :eq]
      end)

    is_weekend || is_holiday
  end
end
