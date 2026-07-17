defmodule MehrSchulferien.VacationOptimization do
  @moduledoc """
  Context module for vacation optimization calculations.

  Given X vacation days, finds the optimal time windows to maximize
  consecutive free days by leveraging weekends and public holidays.

  Provides two variants:
  - Normal: Maximizes free time regardless of school vacations
  - Budget: Finds optimal periods outside of school vacations (cheaper travel)
  """

  alias MehrSchulferien.VacationOptimization.Optimizer

  @doc """
  Finds optimal vacation windows for the given location and parameters.

  ## Parameters
    - `location_ids` - List of location IDs (country, federal state)
    - `year` - The year to optimize for
    - `vacation_days` - Number of vacation days available (1-60)
    - `opts` - Options (see below)

  ## Options
    - `:avoid_school_vacations` - If true, excludes periods overlapping school vacations (budget variant)
    - `:include_cross_year` - If true, includes windows spanning Dec-Jan (default: true)
    - `:top` - Number of top results to return (default: 5)

  ## Returns
    List of `%Result{}` structs sorted by efficiency (descending).

  ## Examples

      iex> location_ids = [1, 2]  # Country and federal state IDs
      iex> VacationOptimization.find_optimal_windows(location_ids, 2026, 30)
      [%Result{rank: 1, vacation_days_used: 30, total_free_days: 42, ...}, ...]

      iex> VacationOptimization.find_optimal_windows(location_ids, 2026, 30, avoid_school_vacations: true)
      [%Result{rank: 1, includes_school_vacation: false, ...}, ...]
  """
  def find_optimal_windows(location_ids, year, vacation_days, opts \\ [])
      when is_list(location_ids) and is_integer(year) and vacation_days in 1..60 do
    Optimizer.find_optimal_windows(location_ids, year, vacation_days, opts)
  end

  @doc """
  Finds the best cross-year vacation window (spanning December to January).

  Useful for finding optimal holiday season vacation periods.
  """
  def find_cross_year_window(location_ids, year, vacation_days, opts \\ []) do
    results =
      find_optimal_windows(
        location_ids,
        year,
        vacation_days,
        Keyword.merge(opts, include_cross_year: true, top: 10)
      )

    # Filter for cross-year results and return the best one
    cross_year_results = Enum.filter(results, & &1.spans_year_boundary)

    case cross_year_results do
      [result | _] -> result
      [] -> nil
    end
  end

  @doc """
  Validates vacation days parameter.

  Returns {:ok, days} if valid, {:error, reason} otherwise.
  """
  def validate_vacation_days(days) when is_integer(days) and days >= 1 and days <= 60 do
    {:ok, days}
  end

  def validate_vacation_days(days) when is_integer(days) do
    {:error, :out_of_range}
  end

  def validate_vacation_days(_), do: {:error, :invalid_type}

  @doc """
  Parses days from URL format like "30-tage" to integer.

  Returns {:ok, days} or {:error, :invalid_format}.
  """
  def parse_days_from_url(days_string) when is_binary(days_string) do
    case Regex.run(~r/^(\d{1,2})-tage$/, days_string) do
      [_, days_str] ->
        days = String.to_integer(days_str)
        validate_vacation_days(days)

      _ ->
        {:error, :invalid_format}
    end
  end

  def parse_days_from_url(_), do: {:error, :invalid_format}
end
