defmodule MehrSchulferien.Periods.Grouping do
  @moduledoc """
  Operations for grouping and categorizing periods.

  This module contains functions for grouping periods by various criteria,
  such as vacation type, interval, or time frame.
  """

  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferien.Helpers.DateConstants
  alias MehrSchulferien.Periods.BridgeDayPeriod

  # Import constants as module attributes for use in guards
  @min_bridge_days DateConstants.min_bridge_days()
  @max_bridge_days DateConstants.max_bridge_days()

  @doc """
  Takes a year's periods, from `start_date`, and groups them based on
  the holiday_or_vacation_type.

  The single year starts with the `start_date`, which is usually the current
  date and continues until August 1, the following year (the next year's
  summer vacation).
  """
  def group_periods_single_year(periods, start_date \\ DateHelpers.today_berlin()) do
    {:ok, end_date} = Date.new(start_date.year + 1, 8, 1)

    periods
    |> Enum.drop_while(&(Date.compare(&1.ends_on, start_date) == :lt))
    |> Enum.take_while(&(Date.compare(&1.starts_on, end_date) != :gt))
    |> Enum.chunk_by(& &1.holiday_or_vacation_type.name)
  end

  @doc """
  Returns a list of periods, sorted by the holiday_or_vacation_type names.
  """
  def list_periods_by_vacation_names(periods) do
    periods
    |> Enum.uniq_by(& &1.holiday_or_vacation_type.name)
    |> Enum.sort(&(Date.day_of_year(&1.starts_on) <= Date.day_of_year(&2.starts_on)))
  end

  @doc """
  Returns a map containing periods that are separated by 1..4 days.

  This is used for calculating bridge days.
  """
  def group_by_interval(periods) do
    # First, find direct bridge days between consecutive periods
    direct_bridges = find_direct_bridge_days(periods)

    # Then, find combinations of bridge days that create longer vacation periods
    combined_bridges = find_combined_bridge_days(periods, direct_bridges)

    # Merge the results
    Map.merge(direct_bridges, combined_bridges)
  end

  defp find_direct_bridge_days(periods) do
    periods
    |> Enum.reduce(%{}, fn period, acc ->
      acc =
        if last_period = acc["last_period"] do
          diff = Date.diff(period.starts_on, last_period.ends_on)

          case {diff, acc} do
            {diff, _} when diff not in @min_bridge_days..@max_bridge_days ->
              acc

            {_, %{^diff => value}} ->
              %{acc | diff => value ++ [BridgeDayPeriod.create(last_period, period, diff)]}

            {_, %{}} ->
              Map.put(acc, diff, [BridgeDayPeriod.create(last_period, period, diff)])
          end
        else
          %{}
        end

      Map.put(acc, "last_period", period)
    end)
    |> Map.delete("last_period")
  end

  defp find_combined_bridge_days(periods, direct_bridges) do
    # Look for 1-day bridge days that can be combined
    single_day_bridges = Map.get(direct_bridges, 2, [])

    if length(single_day_bridges) >= 2 do
      # Sort by start date
      sorted_bridges = Enum.sort_by(single_day_bridges, & &1.starts_on)

      # Pre-build a MapSet of holiday dates for O(1) lookups (instead of O(n) per date)
      holiday_date_set = build_holiday_date_set(periods)

      # Find combinations where multiple single-day bridges create a continuous vacation
      combinations = find_bridge_combinations(sorted_bridges, periods, holiday_date_set, 2, 3)

      # Group by total number of bridge days needed
      Enum.reduce(combinations, %{}, fn combo, acc ->
        # Convert to the map key format
        key = combo.number_days + 1
        Map.update(acc, key, [combo], &(&1 ++ [combo]))
      end)
    else
      %{}
    end
  end

  # Build a MapSet of all dates that are public holidays for O(1) lookups
  defp build_holiday_date_set(periods) do
    periods
    |> Enum.filter(& &1.is_public_holiday)
    |> Enum.flat_map(fn p ->
      Date.range(p.starts_on, p.ends_on) |> Enum.to_list()
    end)
    |> MapSet.new()
  end

  defp find_bridge_combinations(bridges, periods, holiday_date_set, _min_days, max_days) do
    # Generate combinations of 2 or 3 single-day bridges
    combinations = []

    # Check pairs of bridges
    combinations =
      if length(bridges) >= 2 do
        combinations ++
          for i <- 0..(length(bridges) - 2),
              j <- (i + 1)..(length(bridges) - 1),
              bridge1 = Enum.at(bridges, i),
              bridge2 = Enum.at(bridges, j),
              combo = check_bridge_combination([bridge1, bridge2], periods, holiday_date_set),
              combo != nil do
            combo
          end
      else
        combinations
      end

    # Check triplets of bridges if max_days >= 3
    combinations =
      if max_days >= 3 && length(bridges) >= 3 do
        combinations ++
          for i <- 0..(length(bridges) - 3),
              j <- (i + 1)..(length(bridges) - 2),
              k <- (j + 1)..(length(bridges) - 1),
              bridge1 = Enum.at(bridges, i),
              bridge2 = Enum.at(bridges, j),
              bridge3 = Enum.at(bridges, k),
              combo =
                check_bridge_combination([bridge1, bridge2, bridge3], periods, holiday_date_set),
              combo != nil do
            combo
          end
      else
        combinations
      end

    combinations
  end

  defp check_bridge_combination(bridges, periods, holiday_date_set) do
    # Sort bridges by start date
    sorted_bridges = Enum.sort_by(bridges, & &1.starts_on)
    first_bridge = List.first(sorted_bridges)
    last_bridge = List.last(sorted_bridges)

    # Check if all days between first and last bridge form a continuous vacation
    # when combined with existing holidays and weekends
    start_check = first_bridge.starts_on
    end_check = last_bridge.ends_on

    # Get all dates in the range
    date_range =
      if Date.compare(start_check, end_check) == :gt do
        Date.range(start_check, end_check, -1)
      else
        Date.range(start_check, end_check)
      end

    # Check if all dates are either:
    # 1. Part of a bridge day we're taking
    # 2. A weekend
    # 3. An existing holiday (using pre-built MapSet for O(1) lookup)
    all_covered =
      Enum.all?(date_range, fn date ->
        is_bridge_day =
          Enum.any?(sorted_bridges, fn bridge ->
            Date.compare(date, bridge.starts_on) != :lt &&
              Date.compare(date, bridge.ends_on) != :gt
          end)

        is_weekend = Date.day_of_week(date) > 5

        # O(1) lookup instead of O(n) Enum.any?
        is_holiday = MapSet.member?(holiday_date_set, date)

        is_bridge_day || is_weekend || is_holiday
      end)

    if all_covered do
      # Calculate total vacation days needed
      total_vacation_days = Enum.sum(Enum.map(sorted_bridges, & &1.number_days))

      # Find the periods this combination connects
      # Use the last_period_id from the first bridge to find the starting period
      first_period = Enum.find(periods, &(&1.id == first_bridge.last_period_id))

      # Find the period after the last bridge
      last_period =
        Enum.find(periods, fn period ->
          Date.compare(period.starts_on, last_bridge.ends_on) == :gt &&
            Date.diff(period.starts_on, last_bridge.ends_on) <= 3
        end)

      if first_period && last_period do
        # Create a combined bridge day period
        %MehrSchulferien.Periods.BridgeDayPeriod{
          starts_on: first_bridge.starts_on,
          ends_on: last_bridge.ends_on,
          number_days: total_vacation_days,
          last_period_id: first_period.id,
          is_school_vacation: true,
          holiday_or_vacation_type: %{
            name:
              if(total_vacation_days > 1,
                do: "Super-Brückentage",
                else: "Brückentag"
              )
          }
        }
      else
        nil
      end
    else
      nil
    end
  end

  def list_periods_with_bridge_day(periods, bridge_day) do
    [before_bd | query_periods] = Enum.drop_while(periods, &(&1.id != bridge_day.last_period_id))
    after_bd_periods = list_consecutive_periods(query_periods)
    query_periods = Enum.take_while(periods, &(&1.id != bridge_day.last_period_id))

    before_bd_periods =
      reverse_list_consecutive_periods([before_bd | Enum.reverse(query_periods)])

    before_bd_periods ++ [bridge_day | after_bd_periods]
  end

  defp list_consecutive_periods([first | rest]) do
    list_consecutive_periods(rest, [first])
  end

  defp list_consecutive_periods([], output), do: output

  defp list_consecutive_periods([first | rest], output) do
    if Date.diff(first.starts_on, List.last(output).ends_on) < DateConstants.min_bridge_days() do
      list_consecutive_periods(rest, output ++ [first])
    else
      output
    end
  end

  defp reverse_list_consecutive_periods([first | rest]) do
    reverse_list_consecutive_periods(rest, [first])
  end

  defp reverse_list_consecutive_periods([], output), do: output

  defp reverse_list_consecutive_periods([first | rest], output) do
    if Date.diff(List.last(output).starts_on, first.ends_on) < DateConstants.min_bridge_days() do
      reverse_list_consecutive_periods(rest, [first | output])
    else
      output
    end
  end
end
