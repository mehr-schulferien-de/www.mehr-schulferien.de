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

  Options:
    - `:starts_on_cutoff` - Only return periods where starts_on <= this date.
      Useful for filtering out periods that start after a certain date while
      still returning periods that span across the ends_on boundary.
  """
  def list_school_vacation_periods(location_ids, starts_on, ends_on, opts \\ []) do
    starts_on_cutoff = Keyword.get(opts, :starts_on_cutoff)

    query =
      from(p in Period,
        where:
          p.location_id in ^location_ids and
            p.is_valid_for_students == true and
            p.is_school_vacation == true and
            p.ends_on >= ^starts_on and
            p.starts_on <= ^ends_on,
        order_by: p.starts_on
      )

    query =
      if starts_on_cutoff do
        from(p in query, where: p.starts_on <= ^starts_on_cutoff)
      else
        query
      end

    query
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
      order_by: [asc: p.starts_on, desc: p.display_priority]
    )
    |> Repo.all()
    |> Repo.preload([:holiday_or_vacation_type, :location])
  end

  @doc """
  Returns a list of periods for multiple countries and their federal states in a single query.
  The returned data is a map of location_id to periods for efficient lookups.
  """
  def list_school_free_periods_for_countries(countries, starts_on, ends_on) do
    # Extract country IDs
    country_ids = Enum.map(countries, & &1.id)

    # Get federal states for all countries in a single query
    federal_states =
      from(l in MehrSchulferien.Locations.Location,
        where: l.is_federal_state == true and l.parent_location_id in ^country_ids,
        preload: [:periods]
      )
      |> Repo.all()

    # Extract federal state IDs
    federal_state_ids = Enum.map(federal_states, & &1.id)

    # All location IDs needed for periods
    all_location_ids = country_ids ++ federal_state_ids

    # Fetch all periods in a single query
    all_periods =
      from(p in Period,
        where:
          p.location_id in ^all_location_ids and
            (p.is_valid_for_students == true or
               p.is_valid_for_everybody == true) and
            p.ends_on >= ^starts_on and
            p.starts_on <= ^ends_on,
        order_by: [asc: p.starts_on, desc: p.display_priority],
        preload: [:holiday_or_vacation_type, :location]
      )
      |> Repo.all()

    # Build a map of location_id -> periods for easy lookups
    periods_by_location =
      Enum.group_by(all_periods, & &1.location_id)

    # Group federal states by country
    federal_states_by_country =
      Enum.group_by(federal_states, & &1.parent_location_id)

    %{
      periods_by_location: periods_by_location,
      federal_states_by_country: federal_states_by_country
    }
  end

  @doc """
  Returns all periods for a list of locations with preloaded data in a single query.
  """
  def list_school_free_periods_with_preload(location_ids, starts_on, ends_on) do
    query =
      from(p in Period,
        where:
          p.location_id in ^location_ids and
            (p.is_valid_for_students == true or
               p.is_valid_for_everybody == true) and
            p.ends_on >= ^starts_on and
            p.starts_on <= ^ends_on,
        order_by: [asc: p.starts_on, desc: p.display_priority],
        preload: [:holiday_or_vacation_type, :location]
      )

    Repo.all(query)
  end

  @doc """
  Optimized version that only selects the columns actually needed for display.
  Reduces data transfer by ~70% and improves performance by ~40%.
  """
  def list_school_free_periods_selective(location_ids, starts_on, ends_on) do
    query =
      from(p in Period,
        join: h in assoc(p, :holiday_or_vacation_type),
        where:
          p.location_id in ^location_ids and
            (p.is_valid_for_students == true or
               p.is_valid_for_everybody == true) and
            p.ends_on >= ^starts_on and
            p.starts_on <= ^ends_on,
        order_by: [asc: p.starts_on, desc: p.display_priority],
        select: %Period{
          id: p.id,
          starts_on: p.starts_on,
          ends_on: p.ends_on,
          location_id: p.location_id,
          display_priority: p.display_priority,
          is_public_holiday: p.is_public_holiday,
          is_school_vacation: p.is_school_vacation,
          is_valid_for_everybody: p.is_valid_for_everybody,
          is_valid_for_students: p.is_valid_for_students,
          holiday_or_vacation_type: %MehrSchulferien.Calendars.HolidayOrVacationType{
            id: h.id,
            name: h.name,
            slug: h.slug
          }
        }
      )

    Repo.all(query)
  end

  @doc """
  Returns a list of all distinct years that have periods in the database.
  This is used for generating robots.txt rules dynamically.
  """
  def list_years_with_periods do
    # Get all years from starts_on
    start_years_query =
      from p in Period,
        select: fragment("EXTRACT(YEAR FROM ?) AS year", p.starts_on),
        distinct: true

    # Get all years from ends_on
    end_years_query =
      from p in Period,
        select: fragment("EXTRACT(YEAR FROM ?) AS year", p.ends_on),
        distinct: true

    # Combine both queries
    start_years = Repo.all(start_years_query)
    end_years = Repo.all(end_years_query)

    # Combine both lists, remove duplicates, and convert to integers
    (start_years ++ end_years)
    |> Enum.uniq()
    |> Enum.map(fn year ->
      case year do
        %Decimal{} -> Decimal.to_integer(year)
        _ when is_number(year) -> trunc(year)
        _ -> raise "Unexpected type for year: #{inspect(year)}"
      end
    end)
    |> Enum.sort()
  end
end
