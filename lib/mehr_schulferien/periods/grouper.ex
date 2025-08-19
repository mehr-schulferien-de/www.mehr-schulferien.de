defmodule MehrSchulferien.Periods.Grouper do
  @moduledoc """
  Groups consecutive periods of the same type (e.g., Bewegliche Ferientage)
  into single periods with date ranges.
  """

  @doc """
  Groups consecutive periods of the same type into single periods.

  Periods are considered consecutive if:
  - They have the same holiday_or_vacation_type
  - They are within 1 day of each other (excluding weekends)
  - They have the same or similar memo

  ## Examples

      iex> periods = [
      ...>   %{holiday_or_vacation_type: %{name: "Beweglicher Ferientag"}, 
      ...>     starts_on: ~D[2026-03-18], ends_on: ~D[2026-03-18], memo: "Mündliches Abitur"},
      ...>   %{holiday_or_vacation_type: %{name: "Beweglicher Ferientag"}, 
      ...>     starts_on: ~D[2026-03-19], ends_on: ~D[2026-03-19], memo: "Mündliches Abitur"}
      ...> ]
      iex> group_consecutive_periods(periods)
      [%{holiday_or_vacation_type: %{name: "Beweglicher Ferientag"}, 
        starts_on: ~D[2026-03-18], ends_on: ~D[2026-03-19], memo: "Mündliches Abitur"}]
  """
  def group_consecutive_periods(periods) when is_list(periods) do
    periods
    |> Enum.sort_by(& &1.starts_on, Date)
    |> Enum.reduce([], &merge_consecutive_period/2)
    |> Enum.reverse()
  end

  defp merge_consecutive_period(period, []) do
    [period]
  end

  defp merge_consecutive_period(period, [last | rest] = acc) do
    if should_merge?(last, period) do
      merged = merge_periods(last, period)
      [merged | rest]
    else
      [period | acc]
    end
  end

  defp should_merge?(period1, period2) do
    same_type?(period1, period2) &&
      consecutive_dates?(period1, period2) &&
      compatible_memo?(period1, period2)
  end

  defp same_type?(period1, period2) do
    type1 = get_type_name(period1)
    type2 = get_type_name(period2)

    # Only merge "Bewegliche Ferientage" for now
    type1 == type2 && type1 == "Beweglicher Ferientag"
  end

  defp get_type_name(period) do
    case period do
      %{holiday_or_vacation_type: %{name: name}} -> name
      _ -> nil
    end
  end

  defp consecutive_dates?(period1, period2) do
    # Check if period2 starts the day after period1 ends
    # or within 3 days (to account for weekends)
    days_between = Date.diff(period2.starts_on, period1.ends_on)
    days_between >= 1 && days_between <= 3
  end

  defp compatible_memo?(period1, period2) do
    memo1 = normalize_memo(Map.get(period1, :memo))
    memo2 = normalize_memo(Map.get(period2, :memo))

    # Memos are compatible if they're the same or both nil/empty
    memo1 == memo2
  end

  defp normalize_memo(nil), do: ""
  defp normalize_memo(""), do: ""

  defp normalize_memo(memo) when is_binary(memo) do
    memo
    |> String.trim()
    |> String.downcase()
  end

  defp normalize_memo(_), do: ""

  defp merge_periods(period1, period2) do
    # Create a new merged period
    merged = Map.put(period1, :ends_on, period2.ends_on)

    # Track how many periods were merged (optional field)
    merged_count1 = Map.get(period1, :merged_count, 1)
    merged_count2 = Map.get(period2, :merged_count, 1)
    Map.put(merged, :merged_count, merged_count1 + merged_count2)
  end
end
