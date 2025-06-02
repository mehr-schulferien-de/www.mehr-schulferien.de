defmodule MehrSchulferien.Periods.Grouping do
  @moduledoc """
  Operations for grouping and categorizing periods.

  This module contains functions for grouping periods by various criteria,
  such as vacation type, interval, or time frame.
  """

  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferien.Periods.BridgeDayPeriod

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
  It iterates through a list of `periods` (assumed to be sorted by start date).
  It looks for pairs of periods where the gap between `last_period.ends_on`
  and `period.starts_on` is between 2 and 5 days (inclusive).
  These gaps represent potential bridge day opportunities.

  The result is a map where keys are the gap duration (e.g., 2, 3, 4, 5 days)
  and values are lists of `BridgeDayPeriod` structs, each representing such an opportunity.
  """
  def group_by_interval(periods) do
    # The accumulator `acc` temporarily stores the `last_period` encountered
    # and accumulates lists of BridgeDayPeriods under keys corresponding to the gap size.
    initial_acc = %{} # No "last_period" initially, and no bridge days found yet.

    periods
    |> Enum.reduce(initial_acc, fn current_period, acc ->
      # Check if there was a 'last_period' processed in the previous iteration.
      new_acc_after_check =
        if last_period = acc["last_period"] do
          # Calculate the difference in days between the start of the current period
          # and the end of the last period.
          # A diff of 1 means they are consecutive (e.g., Mon ends, Tue starts).
          # A diff of 2 means there's 1 day in between (e.g., Fri ends, Sun starts -> Sat is the gap).
          # Bridge days are typically 1-4 actual days off.
          # If period A ends on Day X, and period B starts on Day Y,
          # Date.diff(Y, X) gives the number of days from X to Y, EXCLUDING X.
          # So if diff is 2, there's 1 day in between. (e.g. Mon ends, Wed starts. Diff is 2. Tue is gap)
          # If diff is 5, there are 4 days in between. (e.g. Mon ends, Sat starts. Diff is 5. Tue,Wed,Thu,Fri are gaps)
          diff = Date.diff(current_period.starts_on, last_period.ends_on)

          # We are interested in gaps that can be bridged, typically 1 to 4 days.
          # A `diff` value of 2 means 1 day gap, up to `diff` of 5 meaning 4 days gap.
          if diff in 2..5 do
            bridge_day_info = BridgeDayPeriod.create(last_period, current_period, diff)
            # Add this bridge day opportunity to the list for the specific gap size.
            # The bridge day infos are prepended to keep them in chronological order as periods are processed.
            Map.update(acc, diff, [bridge_day_info], &[bridge_day_info | &1])
          else
            # Gap is not of interest for bridge days, keep accumulator as is for this part.
            acc
          end
        else
          # This is the first period being processed, no `last_period` yet.
          acc # Accumulator remains unchanged for bridge day collection.
        end

      # Update 'last_period' to the current period for the next iteration.
      Map.put(new_acc_after_check, "last_period", current_period)
    end)
    |> Map.delete("last_period") # Remove the temporary 'last_period' key from the final result.
    |> Enum.map(fn {key, val} -> {key, Enum.reverse(val)} end) # Reverse the lists to restore chronological order.
    |> Enum.into(%{})
  end

  @doc """
  Reconstructs a list of periods that are part of a bridge day sequence.
  It takes all relevant `all_sorted_periods` from a broader context (e.g., a year)
  and a `bridge_day_gap_info` which is a `BridgeDayPeriod` struct.
  This `bridge_day_gap_info` represents the "gap" or the user-taken vacation days,
  and it holds references (`last_period_id`, `next_period_id`) to the fixed
  holidays/vacations that occur just before and just after this gap.

  The function aims to return a combined list:
  [sequence of fixed periods before gap, the gap itself, sequence of fixed periods after gap]
  where the sequences are consecutive blocks of holidays.
  """
  def list_periods_with_bridge_day(all_sorted_periods, bridge_day_gap_info) do
    # Find the actual Period struct for the holiday that ends just before the gap.
    period_before_gap =
      Enum.find(all_sorted_periods, &(&1.id == bridge_day_gap_info.last_period_id))

    # Find the actual Period struct for the holiday that starts just after the gap.
    period_after_gap =
      Enum.find(all_sorted_periods, &(&1.id == bridge_day_gap_info.next_period_id))

    # If either adjacent period isn't found in the provided list, something is wrong.
    # For simplicity, this implementation assumes they will be found.
    # A more robust version might handle `nil` cases for `period_before_gap` or `period_after_gap`.

    # Find all periods consecutive with and leading up to `period_before_gap`.
    # First, take all periods up to and including `period_before_gap`.
    index_of_period_before_gap =
      Enum.find_index(all_sorted_periods, &(&1.id == period_before_gap.id))

    periods_up_to_and_including_before_gap =
      Enum.take(all_sorted_periods, index_of_period_before_gap + 1)

    # Then, from this sublist (reversed), find the consecutive sequence ending at `period_before_gap`.
    consecutive_periods_ending_before_gap =
      reverse_list_consecutive_periods(Enum.reverse(periods_up_to_and_including_before_gap))

    # Find all periods consecutive with and starting from `period_after_gap`.
    # First, drop all periods before `period_after_gap`.
    index_of_period_after_gap =
      Enum.find_index(all_sorted_periods, &(&1.id == period_after_gap.id))

    periods_from_after_gap_onwards =
      Enum.drop(all_sorted_periods, index_of_period_after_gap)

    # Then, from this sublist, find the consecutive sequence starting with `period_after_gap`.
    consecutive_periods_starting_after_gap =
      list_consecutive_periods(periods_from_after_gap_onwards)

    # Combine the sequence before the gap, the bridge day gap itself, and the sequence after the gap.
    # The `bridge_day_gap_info` itself is the representation of the gap (e.g., user's vacation days).
    consecutive_periods_ending_before_gap ++ [bridge_day_gap_info | consecutive_periods_starting_after_gap]
  end

  # Helper to find a list of consecutive periods from the beginning of the given `list_of_periods`.
  # `output` accumulates the consecutive periods found so far.
  # Assumes `list_of_periods` is sorted by start date.
  # It is called recursively, building up the `output` list.
  defp list_consecutive_periods([first_period | rest_periods]) do
    # Start the process with the first period as the initial `output`.
    list_consecutive_periods(rest_periods, [first_period])
  end
  # Base case: If there are no `rest_periods` left, the accumulated `output` is returned.
  defp list_consecutive_periods([], output), do: output

  # Internal recursive helper for `list_consecutive_periods`.
  # `next_period` is the current period being considered.
  # `output` is the list of consecutive periods accumulated so far.
  defp list_consecutive_periods([next_period | rest_periods], output) do
    last_collected_period = List.last(output)
    # Check if `next_period` starts less than 2 days after `last_collected_period` ends.
    # This means they are either immediately consecutive (diff=1) or overlap (diff<=0).
    # Diff < 2 is a common way to define "connected" for holiday blocks.
    if Date.diff(next_period.starts_on, last_collected_period.ends_on) < 2 do
      # Periods are consecutive, add `next_period` to output and continue with `rest_periods`.
      list_consecutive_periods(rest_periods, output ++ [next_period])
    else
      # `next_period` is not consecutive with the `last_collected_period`.
      # The sequence of consecutive periods ends here. Return the accumulated `output`.
      output
    end
  end

  # Helper to find a list of consecutive periods from the end of the given `list_of_periods`
  # by processing a reversed version of a sublist.
  # `output` accumulates the consecutive periods.
  # The caller is expected to pass a list that, when processed from head to tail,
  # is equivalent to processing the original desired sublist from tail to head.
  defp reverse_list_consecutive_periods([first_period_from_reversed_list | rest_of_reversed_list]) do
    # Start with the first period (which was effectively the last period of the sublist in original chronological order).
    reverse_list_consecutive_periods(rest_of_reversed_list, [first_period_from_reversed_list])
  end
  defp reverse_list_consecutive_periods([], output), do: output # Base case.

  # Internal recursive helper for `reverse_list_consecutive_periods`.
  # `next_period_from_reversed_list` is the current period being considered from the reversed input.
  # `output` is the list of consecutive periods accumulated so far (in reverse chronological order).
  defp reverse_list_consecutive_periods([next_period_from_reversed_list | rest_of_reversed_list], output) do
    # `List.first(output)` is used here because `output` is being built in reverse chronological order.
    # So, `List.first(output)` is the period chronologically *after* `next_period_from_reversed_list`.
    chronologically_later_period_in_output = List.first(output)

    # Check if `chronologically_later_period_in_output` starts less than 2 days
    # after `next_period_from_reversed_list` ends.
    if Date.diff(chronologically_later_period_in_output.starts_on, next_period_from_reversed_list.ends_on) < 2 do
      # Periods are consecutive. Prepend `next_period_from_reversed_list` to output and continue.
      reverse_list_consecutive_periods(rest_of_reversed_list, [next_period_from_reversed_list | output])
    else
      # Not consecutive. The sequence (in reverse) ends.
      output
    end
  end
end
