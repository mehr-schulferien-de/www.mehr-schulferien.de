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
  """
  def group_by_interval(periods) do
    periods
    |> Enum.reduce(%{}, fn period, acc ->
      acc =
        if last_period = acc["last_period"] do
          diff = Date.diff(period.starts_on, last_period.ends_on)

          case {diff, acc} do
            {diff, _} when diff not in 2..5 ->
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
    if Date.diff(first.starts_on, List.last(output).ends_on) < 2 do
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
    if Date.diff(List.last(output).starts_on, first.ends_on) < 2 do
      reverse_list_consecutive_periods(rest, [first | output])
    else
      output
    end
  end
end
