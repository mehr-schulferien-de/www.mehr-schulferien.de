defmodule MehrSchulferien.Calendars.VacationTypes do
  @moduledoc """
  Functions for working with vacation types for federal states.
  """

  import Ecto.Query
  alias MehrSchulferien.Calendars.HolidayOrVacationType
  alias MehrSchulferien.Helpers.DateConstants
  alias MehrSchulferien.{Periods.Period, Repo}

  @doc """
  Returns the vacation types that exist for a given federal state.

  Only includes vacation types that:
  - Have been used in the -12 month to +12 month range from today
  - Have periods that are at least 3 days long

  ## Examples

      iex> VacationTypes.list_for_federal_state(state, today)
      [%HolidayOrVacationType{slug: "oster", name: "Ostern", ...}, ...]
  """
  def list_for_federal_state(federal_state, today \\ Date.utc_today()) do
    # Calculate date range: 12 months before and after today
    start_date = Date.add(today, -DateConstants.days_per_year())
    end_date = Date.add(today, DateConstants.days_per_year())

    Period
    |> join(:inner, [p], hvt in HolidayOrVacationType,
      on: p.holiday_or_vacation_type_id == hvt.id
    )
    |> where([p, hvt], p.location_id == ^federal_state.id)
    |> where([p, hvt], hvt.default_is_school_vacation == true)
    # Date range filter
    |> where([p, hvt], p.starts_on <= ^end_date and p.ends_on >= ^start_date)
    # Minimum 3 days length filter
    |> where([p, hvt], fragment("? - ? >= 2", p.ends_on, p.starts_on))
    |> distinct([p, hvt], hvt.id)
    |> select([p, hvt], hvt)
    |> order_by([p, hvt], hvt.default_display_priority)
    |> Repo.all()
  end

  @doc """
  Checks if a vacation type exists for a given federal state.
  """
  def exists_for_state?(federal_state, vacation_slug) do
    Period
    |> join(:inner, [p], hvt in HolidayOrVacationType,
      on: p.holiday_or_vacation_type_id == hvt.id
    )
    |> where([p, hvt], p.location_id == ^federal_state.id)
    |> where([p, hvt], hvt.slug == ^vacation_slug)
    |> where([p, hvt], hvt.default_is_school_vacation == true)
    |> Repo.exists?()
  end

  @doc """
  Checks if a vacation type exists for a given federal state in a specific year.

  ## Examples

      iex> VacationTypes.exists_for_year?(federal_state, "oster", 2024)
      true
  """
  def exists_for_year?(federal_state, vacation_slug, year) when is_integer(year) do
    start_date = Date.new!(year, 1, 1)
    end_date = Date.new!(year, 12, 31)

    Period
    |> join(:inner, [p], hvt in HolidayOrVacationType,
      on: p.holiday_or_vacation_type_id == hvt.id
    )
    |> where([p, hvt], p.location_id == ^federal_state.id)
    |> where([p, hvt], hvt.slug == ^vacation_slug)
    |> where([p, hvt], hvt.default_is_school_vacation == true)
    # Check if period overlaps with the year
    |> where([p, hvt], p.starts_on <= ^end_date and p.ends_on >= ^start_date)
    |> Repo.exists?()
  end

  def exists_for_year?(federal_state, vacation_slug, year) when is_binary(year) do
    exists_for_year?(federal_state, vacation_slug, String.to_integer(year))
  end

  @doc """
  Returns vacation types that have periods in a specific year for a federal state.

  ## Examples

      iex> VacationTypes.list_for_year(federal_state, 2024)
      [%HolidayOrVacationType{slug: "oster", ...}, ...]
  """
  def list_for_year(federal_state, year) when is_integer(year) do
    start_date = Date.new!(year, 1, 1)
    end_date = Date.new!(year, 12, 31)

    Period
    |> join(:inner, [p], hvt in HolidayOrVacationType,
      on: p.holiday_or_vacation_type_id == hvt.id
    )
    |> where([p, hvt], p.location_id == ^federal_state.id)
    |> where([p, hvt], hvt.default_is_school_vacation == true)
    # Check if period overlaps with the year
    |> where([p, hvt], p.starts_on <= ^end_date and p.ends_on >= ^start_date)
    # Minimum 3 days length filter
    |> where([p, hvt], fragment("? - ? >= 2", p.ends_on, p.starts_on))
    |> distinct([p, hvt], hvt.id)
    |> select([p, hvt], hvt)
    |> order_by([p, hvt], hvt.default_display_priority)
    |> Repo.all()
  end

  def list_for_year(federal_state, year) when is_binary(year) do
    list_for_year(federal_state, String.to_integer(year))
  end
end
