defmodule MehrSchulferien.Periods.Query do
  @moduledoc """
  Period query operations.

  This module contains functions for querying periods by date ranges, 
  grouping them, and other specialized queries related to time.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferien.Periods.Period
  alias MehrSchulferien.Repo

  @doc """
  Returns a list of previous periods for a federal_state.
  """
  def list_previous_periods(federal_state, holiday_or_vacation_type) do
    today = DateHelpers.today_berlin()

    from(p in Period,
      where:
        p.location_id == ^federal_state.id and
          p.holiday_or_vacation_type_id == ^holiday_or_vacation_type.id and
          p.ends_on < ^today,
      order_by: [desc: p.starts_on]
    )
    |> Repo.all()
    |> Repo.preload([:holiday_or_vacation_type, :location])
  end

  @doc """
  Returns a list of current and future periods for a federal_state.
  """
  def list_current_and_future_periods(federal_state, holiday_or_vacation_type) do
    today = DateHelpers.today_berlin()

    from(p in Period,
      where:
        p.location_id == ^federal_state.id and
          p.holiday_or_vacation_type_id == ^holiday_or_vacation_type.id and
          p.ends_on >= ^today,
      order_by: p.starts_on
    )
    |> Repo.all()
    |> Repo.preload([:holiday_or_vacation_type, :location])
  end

  @doc """
  Returns a list of school vacation periods for a certain time frame.
  """
  def list_school_periods(location_ids, starts_on, ends_on) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          p.is_valid_for_students == true and
          p.is_school_vacation == true and
          p.ends_on >= ^starts_on and
          p.starts_on <= ^ends_on,
      order_by: p.starts_on
    )
    |> Repo.all()
    |> Repo.preload([:holiday_or_vacation_type, :location])
  end

  @doc """
  Returns a list of public holiday periods, and periods that are valid
  for everybody, for a certain time frame.

  This function also returns periods that are valid for everybody, such as
  weekends. If you want to see just the public holiday periods, use
  `list_public_periods` instead.
  """
  def list_public_everybody_periods(location_ids, starts_on, ends_on) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          (p.is_public_holiday == true or
             p.is_valid_for_everybody == true) and
          p.ends_on >= ^starts_on and
          p.starts_on <= ^ends_on,
      order_by: p.starts_on
    )
    |> Repo.all()
    |> Repo.preload([:holiday_or_vacation_type, :location])
  end

  @doc """
  Returns a list of public holiday periods for a certain time frame.
  """
  def list_public_periods(location_ids, starts_on, ends_on) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          p.is_public_holiday == true and
          p.ends_on >= ^starts_on and
          p.starts_on <= ^ends_on,
      order_by: p.display_priority
    )
    |> Repo.all()
    |> Repo.preload([:holiday_or_vacation_type, :location])
  end

  @doc """
  Returns a list of periods that are non-school days for a certain date
  range.
  """
  def list_school_free_periods(location_ids, starts_on, ends_on) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          (p.is_valid_for_students == true or
             p.is_valid_for_everybody == true) and
          p.ends_on >= ^starts_on and
          p.starts_on <= ^ends_on,
      order_by: p.display_priority
    )
    |> Repo.all()
    |> Repo.preload([:holiday_or_vacation_type, :location])
  end
end
