defmodule MehrSchulferien.BridgeDayCalculations do
  @moduledoc """
  Core business logic for bridge day calculations.
  These functions calculate metrics about bridge days without any view concerns.
  """

  @doc """
  Calculates the total number of free days in a sequence of periods.
  """
  def get_number_max_days(periods) when is_list(periods) and length(periods) > 0 do
    start_date = hd(periods).starts_on
    end_date = List.last(periods).ends_on
    Date.diff(end_date, start_date) + 1
  end

  def get_number_max_days([]), do: 0

  @doc """
  Determines if a bridge day opportunity meets the minimum gain threshold.

  The minimum gain is based on how many vacation days you take versus
  how many total free days you get.
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
end
