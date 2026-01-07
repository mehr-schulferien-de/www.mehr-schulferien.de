defmodule MehrSchulferien.VacationOptimization.Result do
  @moduledoc """
  Represents a single vacation optimization result.

  Contains information about an optimal vacation window including:
  - Date range (start_date, end_date)
  - Days breakdown (vacation, weekend, holiday)
  - Efficiency metrics
  - Related metadata (holidays, year boundary)
  """

  @type t :: %__MODULE__{
          rank: pos_integer() | nil,
          start_date: Date.t() | nil,
          end_date: Date.t() | nil,
          vacation_days_used: non_neg_integer(),
          total_free_days: non_neg_integer(),
          weekend_days: non_neg_integer(),
          holiday_days: non_neg_integer(),
          school_vacation_days: non_neg_integer(),
          efficiency_ratio: float(),
          efficiency_percentage: integer(),
          includes_school_vacation: boolean(),
          related_holidays: [String.t()],
          spans_year_boundary: boolean()
        }

  defstruct rank: nil,
            start_date: nil,
            end_date: nil,
            vacation_days_used: 0,
            total_free_days: 0,
            weekend_days: 0,
            holiday_days: 0,
            school_vacation_days: 0,
            efficiency_ratio: 1.0,
            efficiency_percentage: 0,
            includes_school_vacation: false,
            related_holidays: [],
            spans_year_boundary: false

  @doc """
  Creates a new Result from the given attributes.
  Automatically calculates efficiency metrics if not provided.
  """
  def new(attrs) when is_map(attrs) do
    result = struct(__MODULE__, attrs)

    result
    |> calculate_efficiency()
    |> calculate_total_free_days()
  end

  defp calculate_efficiency(%{vacation_days_used: 0} = result), do: result

  defp calculate_efficiency(%{vacation_days_used: vac, total_free_days: total} = result)
       when total > 0 and vac > 0 do
    ratio = total / vac
    percentage = round((total - vac) / vac * 100)

    %{result | efficiency_ratio: ratio, efficiency_percentage: percentage}
  end

  defp calculate_efficiency(result), do: result

  defp calculate_total_free_days(
         %{vacation_days_used: vac, weekend_days: weekend, holiday_days: holiday} = result
       )
       when result.total_free_days == 0 do
    %{result | total_free_days: vac + weekend + holiday}
  end

  defp calculate_total_free_days(result), do: result
end
