defmodule MehrSchulferienWeb.ControllerHelpers do
  @moduledoc """
  Helper functions for use with controllers.
  """

  alias MehrSchulferien.{Calendars.DateHelpers, Periods}

  @months_map %{
    1 => "Januar",
    2 => "Februar",
    3 => "März",
    4 => "April",
    5 => "Mai",
    6 => "Juni",
    7 => "Juli",
    8 => "August",
    9 => "September",
    10 => "Oktober",
    11 => "November",
    12 => "Dezember"
  }

  def list_period_data(location_ids, today) do
    current_year = today.year
    {:ok, first_day} = Date.new(current_year, 1, 1)
    {:ok, last_day} = Date.new(current_year + 2, 12, 31)
    school_periods = Periods.list_school_vacation_periods(location_ids, first_day, last_day)
    public_periods = Periods.list_public_everybody_periods(location_ids, first_day, last_day)
    months = DateHelpers.get_months_map()

    # Group periods by year to determine which years have vacation data
    years_with_data =
      school_periods
      |> Enum.map(& &1.starts_on.year)
      |> Enum.uniq()
      |> Enum.sort()

    # Only include years that have vacation data
    years_to_show =
      Enum.filter([current_year, current_year + 1, current_year + 2], fn year ->
        Enum.member?(years_with_data, year)
      end)

    # Create days only for years with data
    days = Enum.flat_map(years_to_show, &DateHelpers.create_year/1)

    next_years =
      MehrSchulferienWeb.ViewHelpers.comma_join_with_a_final_und(
        Enum.map(years_to_show, &"#{&1}")
      )

    [
      current_year: current_year,
      days: days,
      months: months,
      next_three_years: next_years,
      school_periods: school_periods,
      public_periods: public_periods
    ]
  end

  def list_faq_data(location_ids, today) do
    yesterday = Date.add(today, -1)
    tomorrow = Date.add(today, 1)
    day_after_tomorrow = Date.add(today, 2)

    public_periods = Periods.list_public_periods(location_ids, yesterday, day_after_tomorrow)

    school_free_periods =
      Periods.list_school_free_periods(location_ids, yesterday, day_after_tomorrow)

    yesterdays_public_holiday_periods = Periods.find_all_periods(public_periods, yesterday)
    todays_public_holiday_periods = Periods.find_all_periods(public_periods, today)
    tomorrows_public_holiday_periods = Periods.find_all_periods(public_periods, tomorrow)

    day_after_tomorrows_public_holiday_periods =
      Periods.find_all_periods(public_periods, day_after_tomorrow)

    yesterdays_school_free_periods = Periods.find_all_periods(school_free_periods, yesterday)
    todays_school_free_periods = Periods.find_all_periods(school_free_periods, today)
    tomorrows_school_free_periods = Periods.find_all_periods(school_free_periods, tomorrow)

    day_after_tomorrows_school_free_periods =
      Periods.find_all_periods(school_free_periods, day_after_tomorrow)

    [
      day_after_tomorrow: day_after_tomorrow,
      day_after_tomorrows_public_holiday_periods: day_after_tomorrows_public_holiday_periods,
      day_after_tomorrows_school_free_periods: day_after_tomorrows_school_free_periods,
      today: today,
      todays_public_holiday_periods: todays_public_holiday_periods,
      todays_school_free_periods: todays_school_free_periods,
      tomorrow: tomorrow,
      tomorrows_public_holiday_periods: tomorrows_public_holiday_periods,
      tomorrows_school_free_periods: tomorrows_school_free_periods,
      yesterday: yesterday,
      yesterdays_public_holiday_periods: yesterdays_public_holiday_periods,
      yesterdays_school_free_periods: yesterdays_school_free_periods
    ]
  end

  @doc """
  Shared logic for show_year controller actions.
  Handles the common pattern of:
  - Year range calculation
  - Period fetching and grouping
  - Data availability checking
  - FAQ data preparation
  """
  def prepare_show_year_data(location_ids, year, today, opts \\ []) do
    # Convert year to integer if it's a string
    year = if is_binary(year), do: String.to_integer(year), else: year

    # Get current year for reference
    current_year = Date.utc_today().year

    # Define the range of years to check (current year and 3 years in each direction)
    check_years = (year - 3)..(year + 3) |> Enum.to_list()

    # Get vacation periods for the entire range with a single query
    range_start = Date.from_erl!({Enum.min(check_years), 1, 1})
    range_end = Date.from_erl!({Enum.max(check_years), 12, 31})

    all_periods = Periods.list_school_vacation_periods(location_ids, range_start, range_end)

    # Group periods by year
    periods_by_year = Enum.group_by(all_periods, fn period -> period.starts_on.year end)

    # Determine which years have data
    years_with_data =
      Enum.filter(check_years, fn check_year ->
        case Map.get(periods_by_year, check_year) do
          nil -> false
          periods -> length(periods) > 0
        end
      end)
      |> Enum.sort()

    # Get periods for the requested year
    current_year_periods = Map.get(periods_by_year, year, [])

    # Handle school-specific extension (include next year until July 31st)
    extended_periods =
      if opts[:extend_to_next_july] do
        next_year_periods = Map.get(periods_by_year, year + 1, [])

        next_year_july_periods =
          Enum.filter(next_year_periods, fn period ->
            {:ok, july_end_date} = Date.new(year + 1, 7, 31)
            Date.compare(period.starts_on, july_end_date) in [:lt, :eq]
          end)

        current_year_periods ++ next_year_july_periods
      else
        current_year_periods
      end

    # Check if data exists for the requested period
    has_data = length(extended_periods) > 0

    # Get public holiday periods for the appropriate date range
    {year_start, year_end} =
      if opts[:extend_to_next_july] do
        {:ok, start_date} = Date.new(year, 1, 1)
        {:ok, end_date} = Date.new(year + 1, 7, 31)
        {start_date, end_date}
      else
        {:ok, start_date} = Date.new(year, 1, 1)
        {:ok, end_date} = Date.new(year, 12, 31)
        {start_date, end_date}
      end

    public_periods = Periods.list_public_periods(location_ids, year_start, year_end)

    # Get FAQ data
    faq_data = list_faq_data(location_ids, today)

    # Calculate next_schulferien_periods (up to 3 periods) for the FAQ
    sorted_periods =
      Enum.sort(
        public_periods ++ extended_periods,
        &(Date.compare(&1.starts_on, &2.starts_on) == :lt)
      )

    next_schulferien_periods = Periods.next_periods(sorted_periods, 3)

    %{
      year: year,
      years_with_data: years_with_data,
      current_year: current_year,
      periods: extended_periods,
      public_periods: public_periods,
      all_periods: extended_periods ++ public_periods,
      has_data: has_data,
      today: today,
      school_periods: extended_periods,
      next_schulferien_periods: next_schulferien_periods,
      months: @months_map,
      faq_data: faq_data
    }
  end

  @doc """
  Calculate effective duration for a period, including adjacent holidays/weekends.
  This function is used by view helpers in all three controllers.
  """
  def calculate_period_effective_duration(period, all_periods) do
    # Get official duration
    official_duration = Date.diff(period.ends_on, period.starts_on) + 1

    # Pre-build holiday date set for O(1) lookups instead of O(n) per date
    holiday_dates = build_holiday_date_set(all_periods)

    # Check days before the period start
    days_before = get_adjacent_days_before(period.starts_on, holiday_dates) |> length()

    # Check days after the period end
    days_after = get_adjacent_days_after(period.ends_on, holiday_dates) |> length()

    # Return total effective duration
    official_duration + days_before + days_after
  end

  # Build a MapSet of all holiday dates for O(1) lookups
  defp build_holiday_date_set(periods) do
    Enum.reduce(periods, MapSet.new(), fn period, acc ->
      Date.range(period.starts_on, period.ends_on)
      |> Enum.reduce(acc, &MapSet.put(&2, &1))
    end)
  end

  # Get days before a date that are already non-school days
  defp get_adjacent_days_before(start_date, holiday_dates) do
    # Start checking from the day before the period
    day_before = Date.add(start_date, -1)

    # Look back up to 7 days (to catch full weekends + holidays)
    dates_to_check = for i <- 0..6, do: Date.add(day_before, -i)

    # Keep only consecutive days off
    Enum.take_while(dates_to_check, fn date ->
      is_weekend_or_holiday?(date, holiday_dates)
    end)
  end

  # Get days after a date that are already non-school days
  defp get_adjacent_days_after(end_date, holiday_dates) do
    # Start checking from the day after the period
    day_after = Date.add(end_date, 1)

    # Look ahead up to 7 days (to catch full weekends + holidays)
    dates_to_check = for i <- 0..6, do: Date.add(day_after, i)

    # Keep only consecutive days off
    Enum.take_while(dates_to_check, fn date ->
      is_weekend_or_holiday?(date, holiday_dates)
    end)
  end

  # Check if a date is a weekend or part of any holiday period (O(1) with MapSet)
  defp is_weekend_or_holiday?(date, holiday_dates) do
    # Weekend check (day_of_week: 6=Saturday, 7=Sunday)
    is_weekend = Date.day_of_week(date) > 5

    # Holiday check - O(1) MapSet lookup instead of O(n) Enum.any?
    is_holiday = MapSet.member?(holiday_dates, date)

    is_weekend || is_holiday
  end

  @doc """
  Get the months map used across controllers.
  """
  def get_months_map, do: @months_map
end
