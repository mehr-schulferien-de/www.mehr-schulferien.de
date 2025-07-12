defmodule MehrSchulferien.Calendars.VacationTypes do
  @moduledoc """
  Functions for working with vacation types for federal states.
  """

  import Ecto.Query
  alias MehrSchulferien.{Repo, Periods.Period, Calendars.HolidayOrVacationType}

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
    start_date = Date.add(today, -365)
    end_date = Date.add(today, 365)

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
end
