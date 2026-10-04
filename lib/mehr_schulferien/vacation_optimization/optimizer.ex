defmodule MehrSchulferien.VacationOptimization.Optimizer do
  @moduledoc """
  Core optimization algorithm for finding optimal vacation windows.

  Given a number of vacation days, finds the time windows that maximize
  total consecutive free days by leveraging weekends and public holidays.
  """

  alias MehrSchulferien.Periods
  alias MehrSchulferien.VacationOptimization.Result

  @doc """
  Finds optimal vacation windows for the given parameters.

  ## Options
    - `:avoid_school_vacations` - If true, excludes periods overlapping school vacations
    - `:include_cross_year` - If true, includes windows spanning Dec-Jan (default: true)
    - `:top` - Number of top results to return (default: 5)

  Returns a list of Result structs sorted by efficiency (descending).
  """
  def find_optimal_windows(location_ids, year, vacation_days, opts \\ []) do
    avoid_school_vacations = Keyword.get(opts, :avoid_school_vacations, false)
    include_cross_year = Keyword.get(opts, :include_cross_year, true)
    top = Keyword.get(opts, :top, 5)

    # Build date range for the year (with optional extension for cross-year)
    {:ok, year_start} = Date.new(year, 1, 1)
    {:ok, year_end} = Date.new(year, 12, 31)

    # Extend range for cross-year calculation. The end has to leave room for a
    # window that starts on 31 December to spend the whole budget: one that
    # runs out of calendar stops early and ranks above every full window.
    extended_start = if include_cross_year, do: Date.add(year_start, -15), else: year_start

    extended_end =
      if include_cross_year, do: Date.add(year_end, 2 * vacation_days + 14), else: year_end

    # Fetch all relevant periods (only actual public holidays, not weekend periods)
    public_periods =
      Periods.list_public_periods(location_ids, extended_start, extended_end)

    school_vacations =
      if avoid_school_vacations do
        Periods.list_school_vacation_periods(location_ids, extended_start, extended_end)
      else
        []
      end

    # Build day classification map
    day_map =
      build_day_classification_map(extended_start, extended_end, public_periods, school_vacations)

    # Find all possible windows
    windows =
      find_all_windows(day_map, vacation_days, year_start, year_end, avoid_school_vacations)

    # Sort and take top N: efficiency first (descending), then fewer school
    # vacation days, which only the budget variant counts. The window's dates
    # come last: the windows arrive in map iteration order, which is
    # undefined, and without a last key equally efficient windows swapped
    # places in production after a restart of the VM.
    sorted_windows =
      Enum.sort_by(windows, fn w ->
        {-w.efficiency_ratio, w.school_vacation_days, date_key(w)}
      end)

    sorted_windows
    # Filter to only include windows that START in the requested year
    # (they can end in the following year, but must start in the requested year)
    |> Enum.filter(fn w -> w.start_date.year == year end)
    |> Enum.take(top)
    |> Enum.with_index(1)
    |> Enum.map(fn {result, rank} -> %{result | rank: rank} end)
  end

  defp date_key(window) do
    {Date.to_gregorian_days(window.start_date), Date.to_gregorian_days(window.end_date)}
  end

  @doc """
  Builds a map classifying each day in the range.

  Returns a map of date => {:weekend | :holiday | :school_vacation | :workday, period_info}
  """
  def build_day_classification_map(start_date, end_date, public_periods, school_vacations) do
    # Pre-build sets for O(1) lookups
    holiday_map = build_period_map(public_periods)
    school_vacation_map = build_period_map(school_vacations)

    Date.range(start_date, end_date)
    |> Enum.map(fn date ->
      classification = classify_day(date, holiday_map, school_vacation_map)
      {date, classification}
    end)
    |> Map.new()
  end

  defp build_period_map(periods) do
    periods
    |> Enum.flat_map(fn period ->
      Date.range(period.starts_on, period.ends_on)
      |> Enum.map(fn date -> {date, period} end)
    end)
    |> Map.new()
  end

  defp classify_day(date, holiday_map, school_vacation_map) do
    is_weekend = Date.day_of_week(date) in [6, 7]
    holiday_period = Map.get(holiday_map, date)
    school_vacation_period = Map.get(school_vacation_map, date)

    cond do
      holiday_period != nil -> {:holiday, holiday_period}
      school_vacation_period != nil -> {:school_vacation, school_vacation_period}
      is_weekend -> {:weekend, nil}
      true -> {:workday, nil}
    end
  end

  defp find_all_windows(day_map, vacation_days, year_start, year_end, avoid_school_vacations) do
    dates = day_map |> Map.keys() |> Enum.sort(Date)

    if avoid_school_vacations do
      # For budget mode: find windows in gaps between school vacations
      find_windows_avoiding_school_vacations(day_map, vacation_days, year_end)
    else
      # For normal mode: calculate windows from each possible start date
      dates
      |> Enum.filter(fn date ->
        # Only start from dates within the main year or slightly before for cross-year
        Date.compare(date, Date.add(year_start, -vacation_days)) != :lt and
          Date.compare(date, year_end) != :gt
      end)
      |> Enum.map(fn start_date ->
        calculate_window_from_start(start_date, vacation_days, day_map, false)
      end)
      |> Enum.filter(fn result -> result != nil and result.total_free_days > 0 end)
      |> deduplicate_overlapping_windows()
    end
  end

  # Find optimal windows that completely avoid school vacation periods
  defp find_windows_avoiding_school_vacations(day_map, vacation_days, year_end) do
    dates = day_map |> Map.keys() |> Enum.sort(Date)

    # Find all non-school-vacation date ranges (gaps between school vacations)
    non_school_ranges = find_non_school_vacation_ranges(dates, day_map)

    # For each gap, find the best window using the vacation budget
    non_school_ranges
    |> Enum.flat_map(fn {range_start, range_end} ->
      find_windows_in_range(range_start, range_end, vacation_days, day_map, year_end)
    end)
    |> Enum.filter(fn result -> result != nil and result.total_free_days > 0 end)
    |> deduplicate_overlapping_windows()
  end

  # Find contiguous date ranges that don't include school vacations
  defp find_non_school_vacation_ranges(dates, day_map) do
    # Group consecutive non-school-vacation days into ranges
    dates
    |> Enum.reduce([], fn date, acc ->
      {type, _period} = Map.get(day_map, date, {:workday, nil})

      is_school_vacation = type == :school_vacation

      if is_school_vacation do
        # End current range if any
        acc
      else
        case acc do
          [{range_start, prev_date} | rest] ->
            # Check if this date is consecutive
            if Date.diff(date, prev_date) == 1 do
              [{range_start, date} | rest]
            else
              [{date, date}, {range_start, prev_date} | rest]
            end

          [] ->
            [{date, date}]
        end
      end
    end)
    |> Enum.reverse()
    # Only keep ranges that are long enough to be useful (at least 3 days)
    |> Enum.filter(fn {range_start, range_end} ->
      Date.diff(range_end, range_start) >= 2
    end)
  end

  # Find optimal windows within a specific date range
  defp find_windows_in_range(range_start, range_end, vacation_days, day_map, year_end) do
    # Try starting from each date in the range. A window has to start in the
    # requested year, so the days after it are no start dates.
    range_start
    |> Date.range(range_end)
    |> Enum.take_while(&(Date.compare(&1, year_end) != :gt))
    |> Enum.map(fn start_date ->
      calculate_window_in_range(start_date, range_end, vacation_days, day_map)
    end)
    |> Enum.filter(&(&1 != nil))
  end

  # Calculate optimal window starting from a date, confined to a range
  defp calculate_window_in_range(start_date, range_end, vacation_budget, day_map) do
    # First, expand backwards to include any adjacent free days (within the range)
    {actual_start, backward_free} = expand_backward_in_range(start_date, day_map, range_end)

    # Then expand forward using vacation days (within the range)
    {actual_end, forward_stats} =
      expand_forward_in_range(start_date, range_end, vacation_budget, day_map)

    if forward_stats.vacation_used == 0 and backward_free.total == 0 do
      nil
    else
      build_result(
        actual_start,
        actual_end,
        forward_stats,
        backward_free,
        day_map,
        true
      )
    end
  end

  defp expand_backward_in_range(start_date, day_map, _range_end) do
    initial_stats = %{total: 0, weekends: 0, holidays: 0}

    # Go backwards from start_date - 1
    Stream.iterate(Date.add(start_date, -1), &Date.add(&1, -1))
    |> Enum.reduce_while({start_date, initial_stats}, fn date, {_current_start, stats} ->
      case Map.get(day_map, date) do
        nil ->
          {:halt, {Date.add(date, 1), stats}}

        {type, _period} ->
          case type do
            :weekend ->
              {:cont, {date, %{stats | total: stats.total + 1, weekends: stats.weekends + 1}}}

            :holiday ->
              {:cont, {date, %{stats | total: stats.total + 1, holidays: stats.holidays + 1}}}

            :school_vacation ->
              # Stop at school vacation boundary
              {:halt, {Date.add(date, 1), stats}}

            _ ->
              {:halt, {Date.add(date, 1), stats}}
          end
      end
    end)
  end

  defp expand_forward_in_range(start_date, range_end, vacation_budget, day_map) do
    initial_stats = %{
      vacation_used: 0,
      total_free: 0,
      weekends: 0,
      holidays: 0,
      school_vacation_days: 0,
      includes_school_vacation: false,
      related_holidays: MapSet.new()
    }

    # Get all dates from start_date to the end of the day_map (beyond range_end)
    # This allows extending into school vacations if needed
    all_dates = day_map |> Map.keys() |> Enum.sort(Date)
    max_date = List.last(all_dates) || range_end

    Date.range(start_date, max_date)
    |> Enum.reduce_while({start_date, initial_stats}, fn date, {_current_end, stats} ->
      {type, period} = Map.get(day_map, date, {:workday, nil})

      case type do
        :weekend ->
          new_stats = %{
            stats
            | total_free: stats.total_free + 1,
              weekends: stats.weekends + 1
          }

          {:cont, {date, new_stats}}

        :holiday ->
          holiday_name =
            if period && period.holiday_or_vacation_type,
              do:
                period.holiday_or_vacation_type.colloquial || period.holiday_or_vacation_type.name,
              else: "Feiertag"

          new_stats = %{
            stats
            | total_free: stats.total_free + 1,
              holidays: stats.holidays + 1,
              related_holidays: MapSet.put(stats.related_holidays, holiday_name)
          }

          {:cont, {date, new_stats}}

        :school_vacation ->
          # Continue into school vacation if we have vacation budget left
          # Track the school vacation days for ranking purposes
          if stats.vacation_used < vacation_budget do
            new_stats = %{
              stats
              | vacation_used: stats.vacation_used + 1,
                total_free: stats.total_free + 1,
                school_vacation_days: stats.school_vacation_days + 1,
                includes_school_vacation: true
            }

            {:cont, {date, new_stats}}
          else
            {:halt, {Date.add(date, -1), stats}}
          end

        :workday ->
          if stats.vacation_used < vacation_budget do
            new_stats = %{
              stats
              | vacation_used: stats.vacation_used + 1,
                total_free: stats.total_free + 1
            }

            {:cont, {date, new_stats}}
          else
            {:halt, {Date.add(date, -1), stats}}
          end
      end
    end)
  end

  @doc """
  Calculates the optimal window starting from a given date.

  Uses a greedy approach: expand forward consuming vacation days for workdays,
  getting free days for weekends/holidays.
  """
  def calculate_window_from_start(start_date, vacation_budget, day_map, avoid_school_vacations) do
    # Try to expand from this start date
    dates = day_map |> Map.keys() |> Enum.sort(Date)
    start_idx = Enum.find_index(dates, fn d -> d == start_date end)

    if start_idx == nil do
      nil
    else
      # First, expand backwards to include any adjacent free days
      {actual_start, backward_free} = expand_backward(start_date, day_map, dates)

      # Then expand forward using vacation days
      {actual_end, forward_stats} =
        expand_forward(start_date, vacation_budget, day_map, dates, avoid_school_vacations)

      if forward_stats.vacation_used == 0 and backward_free.total == 0 do
        nil
      else
        build_result(
          actual_start,
          actual_end,
          forward_stats,
          backward_free,
          day_map,
          avoid_school_vacations
        )
      end
    end
  end

  defp expand_backward(start_date, day_map, dates) do
    start_idx = Enum.find_index(dates, fn d -> d == start_date end) || 0

    # Go backwards from start_date - 1
    initial_stats = %{total: 0, weekends: 0, holidays: 0}

    Enum.reduce_while((start_idx - 1)..0//-1, {start_date, initial_stats}, fn idx,
                                                                              {_current_start,
                                                                               stats} ->
      date = Enum.at(dates, idx)
      {type, _period} = Map.get(day_map, date, {:workday, nil})

      case type do
        :weekend ->
          {:cont, {date, %{stats | total: stats.total + 1, weekends: stats.weekends + 1}}}

        :holiday ->
          {:cont, {date, %{stats | total: stats.total + 1, holidays: stats.holidays + 1}}}

        _ ->
          {:halt, {Date.add(date, 1), stats}}
      end
    end)
  end

  defp expand_forward(start_date, vacation_budget, day_map, dates, avoid_school_vacations) do
    start_idx = Enum.find_index(dates, fn d -> d == start_date end) || 0
    max_idx = length(dates) - 1

    initial_stats = %{
      vacation_used: 0,
      total_free: 0,
      weekends: 0,
      holidays: 0,
      includes_school_vacation: false,
      related_holidays: MapSet.new()
    }

    Enum.reduce_while(start_idx..max_idx, {start_date, initial_stats}, fn idx,
                                                                          {_current_end, stats} ->
      date = Enum.at(dates, idx)
      {type, period} = Map.get(day_map, date, {:workday, nil})

      case type do
        :weekend ->
          new_stats = %{
            stats
            | total_free: stats.total_free + 1,
              weekends: stats.weekends + 1
          }

          {:cont, {date, new_stats}}

        :holiday ->
          holiday_name =
            if period && period.holiday_or_vacation_type,
              do:
                period.holiday_or_vacation_type.colloquial || period.holiday_or_vacation_type.name,
              else: "Feiertag"

          new_stats = %{
            stats
            | total_free: stats.total_free + 1,
              holidays: stats.holidays + 1,
              related_holidays: MapSet.put(stats.related_holidays, holiday_name)
          }

          {:cont, {date, new_stats}}

        :school_vacation when avoid_school_vacations ->
          # In budget mode, stop at school vacation boundaries
          {:halt, {Date.add(date, -1), stats}}

        :school_vacation ->
          # In normal mode, treat school vacation days as workdays (need vacation)
          if stats.vacation_used < vacation_budget do
            new_stats = %{
              stats
              | vacation_used: stats.vacation_used + 1,
                total_free: stats.total_free + 1,
                includes_school_vacation: true
            }

            {:cont, {date, new_stats}}
          else
            {:halt, {Date.add(date, -1), stats}}
          end

        :workday ->
          if stats.vacation_used < vacation_budget do
            new_stats = %{
              stats
              | vacation_used: stats.vacation_used + 1,
                total_free: stats.total_free + 1
            }

            {:cont, {date, new_stats}}
          else
            {:halt, {Date.add(date, -1), stats}}
          end
      end
    end)
  end

  defp build_result(
         actual_start,
         actual_end,
         forward_stats,
         backward_free,
         _day_map,
         _avoid_school_vacations
       ) do
    total_free =
      forward_stats.total_free + backward_free.total

    total_weekends = forward_stats.weekends + backward_free.weekends
    total_holidays = forward_stats.holidays + backward_free.holidays

    vacation_days = forward_stats.vacation_used

    # Get school_vacation_days from forward_stats (defaults to 0 if not present)
    school_vacation_days = Map.get(forward_stats, :school_vacation_days, 0)

    spans_year = actual_start.year != actual_end.year

    if vacation_days == 0 and total_free == 0 do
      nil
    else
      efficiency_ratio = if vacation_days > 0, do: total_free / vacation_days, else: 0

      efficiency_pct =
        if vacation_days > 0,
          do: round((total_free - vacation_days) / vacation_days * 100),
          else: 0

      %Result{
        start_date: actual_start,
        end_date: actual_end,
        vacation_days_used: vacation_days,
        total_free_days: total_free,
        weekend_days: total_weekends,
        holiday_days: total_holidays,
        school_vacation_days: school_vacation_days,
        efficiency_ratio: efficiency_ratio,
        efficiency_percentage: efficiency_pct,
        includes_school_vacation: forward_stats.includes_school_vacation,
        related_holidays: MapSet.to_list(forward_stats.related_holidays),
        spans_year_boundary: spans_year
      }
    end
  end

  defp deduplicate_overlapping_windows(windows) do
    # Group by similar date ranges and keep the best one
    windows
    |> Enum.group_by(fn w -> {w.start_date, w.end_date} end)
    |> Enum.map(fn {_key, group} ->
      Enum.max_by(group, & &1.efficiency_ratio)
    end)
  end

  @doc """
  Filters a list of results to return only distinct (non-overlapping) results.

  Two results are considered "overlapping" if they share more than the specified
  threshold of days. Default threshold is 0.7 (70%).

  Returns up to `max_results` distinct results, keeping the highest efficiency ones.
  """
  def filter_distinct_results(results, opts \\ []) do
    overlap_threshold = Keyword.get(opts, :overlap_threshold, 0.7)
    max_results = Keyword.get(opts, :max_results, 3)

    results
    |> Enum.reduce([], fn result, acc ->
      if Enum.any?(acc, fn existing -> overlaps_too_much?(result, existing, overlap_threshold) end) do
        acc
      else
        [result | acc]
      end
    end)
    |> Enum.reverse()
    |> Enum.take(max_results)
    # Re-rank the filtered results (1, 2, 3 instead of original ranks)
    |> Enum.with_index(1)
    |> Enum.map(fn {result, rank} -> %{result | rank: rank} end)
  end

  defp overlaps_too_much?(result1, result2, threshold) do
    # Calculate the overlap between two date ranges
    overlap_start = max_date(result1.start_date, result2.start_date)
    overlap_end = min_date(result1.end_date, result2.end_date)

    if Date.compare(overlap_start, overlap_end) == :gt do
      # No overlap
      false
    else
      overlap_days = Date.diff(overlap_end, overlap_start) + 1
      result1_days = Date.diff(result1.end_date, result1.start_date) + 1
      result2_days = Date.diff(result2.end_date, result2.start_date) + 1

      # Use the smaller period for the overlap ratio
      min_days = min(result1_days, result2_days)
      overlap_ratio = overlap_days / min_days

      overlap_ratio > threshold
    end
  end

  defp max_date(d1, d2), do: if(Date.compare(d1, d2) == :gt, do: d1, else: d2)
  defp min_date(d1, d2), do: if(Date.compare(d1, d2) == :lt, do: d1, else: d2)

  @doc """
  Computes the specific vacation dates (workdays user needs to take off) for a result.

  Returns a list of dates that are:
  - Within the result's date range
  - Not weekends
  - Not public holidays

  These are the days the user actually needs to use vacation days for.
  """
  def compute_vacation_dates(result, public_periods) do
    Date.range(result.start_date, result.end_date)
    |> Enum.filter(fn date ->
      weekday = Date.day_of_week(date)
      is_weekend = weekday in [6, 7]

      is_holiday =
        Enum.any?(public_periods, fn period ->
          Date.compare(period.starts_on, date) != :gt and
            Date.compare(period.ends_on, date) != :lt
        end)

      # It's a vacation day if it's NOT a weekend and NOT a holiday
      not is_weekend and not is_holiday
    end)
  end
end
