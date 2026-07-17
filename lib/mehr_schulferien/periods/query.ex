defmodule MehrSchulferien.Periods.Query do
  @moduledoc """
  Period query operations.

  This module contains functions for querying periods by date ranges, 
  grouping them, and other specialized queries related to time.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Periods.Period
  alias MehrSchulferien.Repo

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
    school_free_periods_query(location_ids, starts_on, ends_on)
    |> Repo.all()
    |> Repo.preload([:holiday_or_vacation_type, :location])
  end

  defp school_free_periods_query(location_ids, starts_on, ends_on) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          (p.is_valid_for_students == true or
             p.is_valid_for_everybody == true) and
          p.ends_on >= ^starts_on and
          p.starts_on <= ^ends_on,
      order_by: [asc: p.starts_on, desc: p.display_priority]
    )
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
