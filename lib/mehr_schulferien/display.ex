defmodule MehrSchulferien.Display do
  @moduledoc """
  The Display context.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Calendars.Period
  alias MehrSchulferien.Maps.Location
  alias MehrSchulferien.Repo

  @doc """
  Returns the list of federal_states.
  """
  def list_federal_states do
    Location |> where(is_federal_state: true) |> Repo.all()
  end

  @doc """
  Gets a single federal_state.

  Raises `Ecto.NoResultsError` if the federal state does not exist.
  """
  def get_federal_state!(id) do
    Repo.get_by!(Location, id: id, is_federal_state: true)
  end

  # NOTE: riverrun (06 Feb 2020)
  # This function might no longer be needed.
  @doc """
  Returns the current school year - written as two years separated by a hyphen.
  """
  def get_current_school_year(today) do
    current_year = today.year

    case today.month do
      x when x < 8 ->
        Enum.join([current_year - 1, current_year], "-")

      _ ->
        Enum.join([current_year, current_year + 1], "-")
    end
  end

  @doc """
  Returns a list of periods for a certain time frame.
  """
  def get_periods_by_time(location_ids, starts_on, ends_on, inclusive) do
    location_ids
    |> query_periods(starts_on, ends_on, inclusive)
    |> Repo.all()
    |> Repo.preload(:holiday_or_vacation_type)
  end

  defp query_periods(location_ids, starts_on, ends_on, true) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          p.is_valid_for_students == true and
          p.is_school_vacation == true and
          p.ends_on >= ^starts_on and
          p.starts_on <= ^ends_on,
      order_by: p.starts_on
    )
  end

  defp query_periods(location_ids, starts_on, ends_on, _) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          p.is_valid_for_students == true and
          p.is_school_vacation == true and
          p.starts_on >= ^starts_on and
          p.starts_on <= ^ends_on,
      order_by: p.starts_on
    )
  end
end
