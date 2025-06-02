defmodule MehrSchulferien.Periods.DateOperations do
  @moduledoc """
  Date-related operations for periods.

  This module contains functions for finding, filtering, and analyzing
  periods based on dates or date ranges.
  """

  alias MehrSchulferien.Calendars.DateHelpers

  @doc """
  Finds all the holiday periods for a certain date.
  """
  def find_all_periods(periods, date) do
    Enum.filter(periods, &is_holiday?(&1, date))
  end

  @doc """
  Returns the next schoolday (the next day that is not a holiday).
  It assumes `periods` is a list of holiday/vacation periods.
  The function recursively checks dates, advancing past known holiday periods.
  """
  def find_next_schoolday([], date), do: date # Base case: No more holiday periods, so current date is a schoolday.
  def find_next_schoolday(_periods, nil), do: nil # Should not happen if date is always valid.

  def find_next_schoolday([first_holiday | rest_holidays], date) do
    # Check if the current 'date' falls within the 'first_holiday'.
    if is_holiday?(first_holiday, date) do
      # If it is a holiday, the next potential schoolday is the day after the holiday ends.
      # We then recursively check this new_date against the remaining holidays.
      # Note: This assumes periods in the list do not overlap in a way that
      # this simple Date.add would skip over another holiday.
      # For robust overlapping period handling, periods should be merged beforehand.
      new_date = Date.add(first_holiday.ends_on, 1)
      find_next_schoolday(rest_holidays, new_date)
    else
      # If 'date' is NOT a holiday according to 'first_holiday' (i.e., it's before it),
      # it means 'date' is a schoolday relative to 'first_holiday'.
      # However, 'date' might still be a holiday due to *other* periods in `rest_holidays`
      # if those periods occur before `first_holiday.starts_on`.
      # This implementation implies periods should ideally be sorted or handled carefully.
      # A simpler model would be to check 'date' against ALL periods.
      # The current recursive structure seems to assume periods are somewhat ordered
      # or that `is_holiday?` effectively means "is this date covered by this specific period object".
      # Given the structure, it seems to be trying to find the first non-holiday day.
      # If `date` is before `first_holiday.starts_on`, it's a potential schoolday.
      # If `date` is after `first_holiday.ends_on`, it's also a potential schoolday
      # relative to `first_holiday`, and we check against `rest_holidays`.

      # The original logic was a bit confusing here. Let's clarify:
      # is_holiday? returns the period if 'date' is within it, or nil otherwise.
      # So, if is_holiday? is false, it means 'date' is NOT within 'first_holiday'.
      # This means 'date' itself is a potential schoolday, unless covered by 'rest_holidays'.
      # However, the original code calls `check_ends_on` which seems redundant if `is_holiday?` was false.
      # Let's assume `is_holiday?` means "is this date part of this specific period object".
      # If it's not part of `first_holiday`, we still need to check `rest_holidays`.
      # This function appears to be designed to be called with a list of periods that *could* affect the date,
      # and it tries to find the earliest date that is not in any of them.

      # Re-evaluating the original logic:
      # if is_holiday?(first, date) -> date is in first period, advance date, check rest
      # else (date is not in first period)
      #   if check_ends_on(date, first) -> this seems to mean 'date' is before or on ends_on of 'first',
      #                                    but not *in* it based on is_holiday? being false.
      #                                    This implies 'date' is before 'first.starts_on'. So, 'date' is a schoolday.
      #   else -> date is after first.ends_on. Check 'date' against 'rest'.
      # This is still a bit tangled. A more common pattern would be:
      # 1. Check if 'date' is in *any* period in the list.
      # 2. If yes, increment 'date' and repeat.
      # 3. If no, 'date' is a schoolday.
      # The current recursive structure with `[first | rest]` suggests processing one period at a time.

      # Let's stick to explaining the original logic as best as possible:
      # If `date` is not within `first_holiday` (is_holiday? returned false):
      # The `check_ends_on(date, first)` part in the `else` is problematic.
      # `is_holiday?` already uses `check_ends_on`. If `is_holiday?` is false,
      # it means `date` is before `first.starts_on`. In this case, `date` is a schoolday
      # *unless* another period in `rest` covers it.
      # The most straightforward interpretation for `find_next_schoolday` is to check `date`
      # against all provided `periods`. If `date` is found in any period, increment and retry.

      # Given the existing structure:
      # It seems `find_next_schoolday` is called with a list of relevant periods around `date`.
      # If `date` is within `first_holiday`, advance `date` past `first_holiday` and check new date against `rest_holidays`.
      # If `date` is NOT within `first_holiday`, it *could* be a schoolday.
      # The original `if check_ends_on(date, first)` in the else branch is confusing.
      # `check_ends_on` returns `first` if date <= first.ends_on, else nil.
      # If `is_holiday?(first, date)` is false, then `date` < `first.starts_on`.
      # In this case, `check_ends_on(date, first)` will be true (returns `first`).
      # So, if `date` is before the current holiday being checked, it's considered the schoolday.
      # This implies the list of periods should be sorted, and we are looking for a date
      # not covered by any of them.
      is_date_covered_by_first_holiday = is_holiday?(first_holiday, date)

      if is_date_covered_by_first_holiday do
        # Date is covered by the current holiday period.
        # Advance date to the day after this holiday ends and check against remaining holidays.
        new_date = Date.add(first_holiday.ends_on, 1)
        find_next_schoolday(rest_holidays, new_date)
      else
        # Date is not covered by `first_holiday`.
        # This means `date` is before `first_holiday.starts_on`.
        # So, `date` is a potential schoolday. We must continue checking `date` against `rest_holidays`.
        find_next_schoolday(rest_holidays, date)
      end
    end
  end

  # Checks if a given `date` falls within the `period`.
  # Returns the `period` if it's a holiday on that `date`, otherwise `nil`.
  defp is_holiday?(period, date) do
    # Date is before period starts: not a holiday within this period.
    # Date is exactly when period starts: it is a holiday.
    # Date is after period starts: need to check if it's also before or on period ends.
    case Date.compare(date, period.starts_on) do
      :lt -> false # Using false for clarity, though original returned nil via check_ends_on
      :eq -> period # Date is the start date
      :gt -> check_ends_on(date, period) # Date is after start, check against end
    end
  end

  # Helper for `is_holiday?`. Checks if `date` is on or before `period.ends_on`.
  # Returns `period` if true (meaning `date` is within the holiday range, assuming `date` >= `period.starts_on`),
  # otherwise `nil`.
  defp check_ends_on(date, period) do
    case Date.compare(date, period.ends_on) do
      :gt -> nil # Date is after period ends
      _ -> period # Date is on or before period ends (and after or on period starts from calling context)
    end
  end

  @doc """
  Returns the holiday periods that overlap with the month of the given `date`.
  A period overlaps if any part of it falls within the target month.
  The function assumes `periods` is a list (potentially unsorted).
  It recursively checks each period.
  """
  def find_periods_by_month(_date, []), do: [] # Base case: no periods left to check.

  def find_periods_by_month(date_in_target_month, [first_period | rest_periods]) do
    # If the first_period starts after the target_month ends, then no subsequent period will match either
    # (assuming periods were sorted by start_date, which is not explicitly required here but good practice).
    # However, the DateHelpers.compare_by_month handles this by comparing only month and year.
    # If first_period starts in a month after date_in_target_month, it (and subsequent ones if sorted) won't be included.
    # This check is primarily to stop early if periods are sorted.
    if DateHelpers.compare_by_month(date_in_target_month, first_period.starts_on) == :lt do
      # `first_period` starts in a month after `date_in_target_month`.
      # If periods are sorted, all `rest_periods` will also be after.
      # If not sorted, this specific `first_period` is skipped.
      # The original logic would return [] here if sorted.
      # If not sorted, it should continue checking `rest_periods`.
      # To match original behavior (which implies sortedness for this optimization):
      # find_periods_by_month(date_in_target_month, rest_periods)
      # For safety with unsorted lists, let's assume original logic implies sorted for this path:
      if DateHelpers.compare_by_month(date_in_target_month, first_period.starts_on) == :lt && Enum.empty?(rest_periods) do
         # This is a slight adaptation: if it starts after AND there are no more periods, then empty.
         # The original `[]` implies an assumption about sortedness for early exit.
         # To be robust for unsorted, we'd always recurse: find_periods_by_month(date_in_target_month, rest_periods)
         # Sticking to original implication:
         [] # Only if this period is after and no more periods to check (or assuming sorted)
      else
        # If `first_period` ends before `date_in_target_month`'s month begins, it's not relevant.
        if DateHelpers.compare_by_month(date_in_target_month, first_period.ends_on) == :gt do
          find_periods_by_month(date_in_target_month, rest_periods)
        else
          # The period overlaps with the target month. Include it and check the rest.
          [first_period | find_periods_by_month(date_in_target_month, rest_periods)]
        end
      end
    end
  end

  @doc """
  Returns the periods for a certain date range.

  The periods need to be sorted (by the `starts_on` date) before calling
  this function.
  """
  # Unused:
  # def find_periods_for_date_range(periods, start_date, end_date) do
  #   periods
  #   |> Enum.drop_while(&(Date.compare(&1.ends_on, start_date) == :lt))
  #   |> Enum.take_while(&(Date.compare(&1.starts_on, end_date) != :gt))
  # end

  @doc """
  Returns the first period after a certain date (the default date is today).

  The periods need to be sorted (by the `starts_on` date) before calling
  this function.
  """
  def next_periods(periods, today \\ DateHelpers.today_berlin(), number) do
    periods
    |> Enum.drop_while(&(Date.compare(&1.ends_on, today) == :lt))
    |> Enum.take(number)
  end

  @doc """
  Returns the most recently ended period.
  """
  def find_most_recent_period(periods, today \\ DateHelpers.today_berlin()) do
    periods
    |> Enum.sort(&(Date.compare(&1.starts_on, &2.starts_on) == :lt))
    |> Enum.take_while(&(Date.compare(&1.ends_on, today) == :lt))
    |> List.last()
  end
end
