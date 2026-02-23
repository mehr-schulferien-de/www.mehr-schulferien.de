defmodule MehrSchulferien.DateQuery do
  @moduledoc """
  The DateQuery context.

  Provides functions to query whether a specific date is a public holiday,
  school day, vacation day, or weekend for a given location.
  """

  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferien.{Locations, Periods}

  @type location :: MehrSchulferien.Locations.Location.t()
  @type query_result :: %{
          date: Date.t(),
          location: location(),
          is_public_holiday: boolean(),
          is_school_day: boolean(),
          is_school_vacation: boolean(),
          is_weekend: boolean(),
          public_holiday_periods: list(),
          school_vacation_periods: list(),
          explanation: String.t()
        }

  @doc """
  Checks comprehensive date status for a location.

  Returns a map with all relevant information about the date:
  - Whether it's a public holiday
  - Whether it's a school day
  - Whether it's a school vacation
  - Whether it's a weekend
  - Lists of relevant periods
  - Human-readable explanation

  ## Examples

      iex> check_date_status(location, ~D[2025-12-25])
      %{
        date: ~D[2025-12-25],
        location: %Location{...},
        is_public_holiday: true,
        is_school_day: false,
        is_school_vacation: true,
        is_weekend: false,
        public_holiday_periods: [%Period{...}],
        school_vacation_periods: [%Period{...}],
        explanation: "1. Weihnachtstag und Weihnachtsferien"
      }
  """
  @spec check_date_status(location(), Date.t()) :: query_result()
  def check_date_status(location, date \\ DateHelpers.today_berlin()) do
    location_ids = Locations.recursive_location_ids(location)

    # Get all periods for this date
    public_periods = Periods.list_public_periods(location_ids, date, date)
    school_periods = Periods.list_school_free_periods(location_ids, date, date)

    # Filter to just this date
    public_holiday_periods =
      public_periods
      |> Enum.filter(&period_includes_date?(&1, date))
      |> MehrSchulferien.Repo.preload(:holiday_or_vacation_type)

    school_vacation_periods =
      school_periods
      |> Enum.filter(&(period_includes_date?(&1, date) and &1.is_school_vacation == true))
      |> MehrSchulferien.Repo.preload(:holiday_or_vacation_type)

    # Determine status
    is_public_holiday = public_holiday_periods != []
    is_school_vacation = school_vacation_periods != []
    is_weekend = weekend?(date)
    is_school_day = not (is_public_holiday or is_school_vacation or is_weekend)

    explanation = build_explanation(date, public_holiday_periods, school_vacation_periods)

    %{
      date: date,
      location: location,
      is_public_holiday: is_public_holiday,
      is_school_day: is_school_day,
      is_school_vacation: is_school_vacation,
      is_weekend: is_weekend,
      public_holiday_periods: public_holiday_periods,
      school_vacation_periods: school_vacation_periods,
      explanation: explanation
    }
  end

  @doc """
  Checks if a specific date is a public holiday in a location.

  Returns a simple boolean and list of holiday periods.

  ## Examples

      iex> is_public_holiday?(location, ~D[2025-12-25])
      {true, [%Period{name: "1. Weihnachtstag", ...}]}
  """
  @spec is_public_holiday?(location(), Date.t()) :: {boolean(), list()}
  def is_public_holiday?(location, date \\ DateHelpers.today_berlin()) do
    location_ids = Locations.recursive_location_ids(location)
    public_periods = Periods.list_public_periods(location_ids, date, date)

    public_holiday_periods =
      public_periods
      |> Enum.filter(&period_includes_date?(&1, date))
      |> MehrSchulferien.Repo.preload(:holiday_or_vacation_type)

    {public_holiday_periods != [], public_holiday_periods}
  end

  @doc """
  Checks if a specific date is a school day in a location.

  A date is a school day if it's not a weekend, not a school vacation,
  and not a public holiday.

  ## Examples

      iex> is_school_day?(location, ~D[2025-09-15])
      {true, []}

      iex> is_school_day?(location, ~D[2025-12-25])
      {false, [%Period{...}]}
  """
  @spec is_school_day?(location(), Date.t()) :: {boolean(), list()}
  def is_school_day?(location, date \\ DateHelpers.today_berlin()) do
    # Weekend check
    if weekend?(date) do
      {false, []}
    else
      location_ids = Locations.recursive_location_ids(location)
      school_periods = Periods.list_school_free_periods(location_ids, date, date)

      school_free_periods =
        school_periods
        |> Enum.filter(&period_includes_date?(&1, date))
        |> MehrSchulferien.Repo.preload(:holiday_or_vacation_type)

      is_school_day = school_free_periods == []
      {is_school_day, school_free_periods}
    end
  end

  @doc """
  Checks if a specific date is a school vacation in a location.

  ## Examples

      iex> is_school_vacation?(location, ~D[2025-07-20])
      {true, [%Period{name: "Sommerferien", ...}]}
  """
  @spec is_school_vacation?(location(), Date.t()) :: {boolean(), list()}
  def is_school_vacation?(location, date \\ DateHelpers.today_berlin()) do
    location_ids = Locations.recursive_location_ids(location)

    vacation_periods =
      location_ids
      |> Periods.list_school_vacation_periods(date, date)
      |> Enum.filter(&period_includes_date?(&1, date))
      |> MehrSchulferien.Repo.preload(:holiday_or_vacation_type)

    {vacation_periods != [], vacation_periods}
  end

  # Private functions

  defp weekend?(date) do
    day_of_week = Date.day_of_week(date)
    day_of_week == 6 or day_of_week == 7
  end

  defp period_includes_date?(period, date) do
    Date.compare(period.starts_on, date) != :gt and
      Date.compare(period.ends_on, date) != :lt
  end

  defp build_explanation(date, public_holiday_periods, school_vacation_periods) do
    cond do
      # Public holiday and vacation
      public_holiday_periods != [] and school_vacation_periods != [] ->
        holiday_names =
          Enum.map_join(public_holiday_periods, ", ", & &1.holiday_or_vacation_type.name)

        vacation_names =
          Enum.map_join(school_vacation_periods, ", ", & &1.holiday_or_vacation_type.colloquial)

        "#{holiday_names} und #{vacation_names}"

      # Just public holiday
      public_holiday_periods != [] ->
        Enum.map_join(public_holiday_periods, ", ", & &1.holiday_or_vacation_type.name)

      # Just vacation
      school_vacation_periods != [] ->
        Enum.map_join(school_vacation_periods, ", ", & &1.holiday_or_vacation_type.colloquial)

      # Weekend
      weekend?(date) ->
        case Date.day_of_week(date) do
          6 -> "Samstag"
          7 -> "Sonntag"
        end

      # Regular school day
      true ->
        "Regulärer Schultag"
    end
  end
end
