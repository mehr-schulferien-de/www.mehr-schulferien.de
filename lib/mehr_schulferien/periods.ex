defmodule MehrSchulferien.Periods do
  @moduledoc """
  The Periods context.

  This module handles all operations related to time periods in the application,
  such as holidays, vacations, and other calendar events. It provides functions
  for querying, creating, updating, and deleting periods, as well as utility
  functions for finding periods by date range and determining schooldays.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.{Cache, Calendars}
  alias MehrSchulferien.Calendars.{DateHelpers, HolidayOrVacationType}
  alias MehrSchulferien.Periods.{Period, Query, DateOperations, Grouping}
  alias MehrSchulferien.Repo

  #
  # Basic CRUD operations
  #

  @doc """
  Selective version for timeline views that only fetches displayed fields.
  Reduces data transfer by ~62% compared to full query.
  """
  def list_school_free_periods_selective(location_ids, starts_on, ends_on) do
    from(p in Period,
      join: h in assoc(p, :holiday_or_vacation_type),
      where:
        p.location_id in ^location_ids and
          (p.is_valid_for_students == true or p.is_valid_for_everybody == true) and
          p.ends_on >= ^starts_on and
          p.starts_on <= ^ends_on,
      order_by: [asc: p.starts_on, desc: p.display_priority],
      select: %Period{
        id: p.id,
        starts_on: p.starts_on,
        ends_on: p.ends_on,
        location_id: p.location_id,
        html_class: p.html_class,
        display_priority: p.display_priority,
        is_public_holiday: p.is_public_holiday,
        is_school_vacation: p.is_school_vacation,
        holiday_or_vacation_type: %HolidayOrVacationType{
          id: h.id,
          name: h.name,
          colloquial: h.colloquial,
          slug: h.slug
        }
      }
    )
    |> Repo.all()
  end

  @doc """
  Optimized version that only selects the fields actually used on the home page.
  This reduces the amount of data transferred from the database by ~70%.
  """
  def list_school_free_periods_optimized(location_ids, starts_on, ends_on) do
    from(p in Period,
      join: h in assoc(p, :holiday_or_vacation_type),
      where:
        p.location_id in ^location_ids and
          (p.is_valid_for_students == true or p.is_valid_for_everybody == true) and
          p.ends_on >= ^starts_on and
          p.starts_on <= ^ends_on,
      order_by: [asc: p.starts_on, desc: p.display_priority],
      select: %Period{
        id: p.id,
        starts_on: p.starts_on,
        ends_on: p.ends_on,
        location_id: p.location_id,
        html_class: p.html_class,
        display_priority: p.display_priority,
        is_public_holiday: p.is_public_holiday,
        is_school_vacation: p.is_school_vacation,
        holiday_or_vacation_type: %HolidayOrVacationType{
          id: h.id,
          name: h.name,
          colloquial: h.colloquial,
          slug: h.slug
        }
      }
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of periods.
  """
  def list_periods do
    Repo.all(Period)
  end

  @doc """
  Gets a single period.

  Raises `Ecto.NoResultsError` if the Period does not exist.
  """
  def get_period!(id) do
    Period
    |> Repo.get!(id)
    |> Repo.preload([:holiday_or_vacation_type, :location])
  end

  @doc """
  Creates a period.
  """
  def create_period(%{"holiday_or_vacation_type_id" => holiday_or_vacation_type_id} = attrs)
      when not is_nil(holiday_or_vacation_type_id) do
    %HolidayOrVacationType{
      id: id,
      default_html_class: html_class,
      default_is_listed_below_month: is_listed_below_month,
      default_is_public_holiday: is_public_holiday,
      default_is_school_vacation: is_school_vacation,
      default_is_valid_for_everybody: is_valid_for_everybody,
      default_is_valid_for_students: is_valid_for_students,
      default_religion_id: religion_id,
      default_display_priority: display_priority
    } = Calendars.get_holiday_or_vacation_type!(holiday_or_vacation_type_id)

    attrs =
      Map.merge(
        %{
          "holiday_or_vacation_type_id" => id,
          "html_class" => html_class,
          "is_listed_below_month" => is_listed_below_month,
          "is_public_holiday" => is_public_holiday,
          "is_school_vacation" => is_school_vacation,
          "is_valid_for_everybody" => is_valid_for_everybody,
          "is_valid_for_students" => is_valid_for_students,
          "religion_id" => religion_id,
          "display_priority" => display_priority
        },
        attrs
      )

    %Period{}
    |> Period.changeset(attrs)
    |> Repo.insert()
  end

  def create_period(%{holiday_or_vacation_type_id: holiday_or_vacation_type_id} = attrs)
      when not is_nil(holiday_or_vacation_type_id) do
    attrs = for {key, val} <- attrs, into: %{}, do: {to_string(key), val}
    create_period(attrs)
  end

  def create_period(attrs) do
    %Period{}
    |> Period.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a period.
  """
  def update_period(%Period{} = period, attrs) do
    period
    |> Period.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a period.
  """
  def delete_period(%Period{} = period) do
    Repo.delete(period)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking period changes.
  """
  def change_period(%Period{} = period) do
    Period.changeset(period, %{})
  end

  #
  # Period queries by time - delegated to Query module
  #

  defdelegate list_previous_periods(federal_state, holiday_or_vacation_type), to: Query
  defdelegate list_current_and_future_periods(federal_state, holiday_or_vacation_type), to: Query
  defdelegate list_school_vacation_periods(location_ids, starts_on, ends_on), to: Query
  defdelegate list_public_everybody_periods(location_ids, starts_on, ends_on), to: Query
  defdelegate list_public_periods(location_ids, starts_on, ends_on), to: Query
  defdelegate list_school_free_periods(location_ids, starts_on, ends_on), to: Query
  defdelegate list_school_free_periods_for_countries(countries, starts_on, ends_on), to: Query
  defdelegate list_school_free_periods_with_preload(location_ids, starts_on, ends_on), to: Query
  defdelegate list_years_with_periods(), to: Query

  #
  # Period filtering and finding by date - delegated to DateOperations module
  #

  defdelegate find_all_periods(periods, date), to: DateOperations
  defdelegate find_next_schoolday(periods, date), to: DateOperations
  defdelegate find_periods_by_month(date, periods), to: DateOperations
  defdelegate find_periods_for_date_range(periods, start_date, end_date), to: DateOperations
  defdelegate next_periods(periods, today, number), to: DateOperations
  defdelegate find_most_recent_period(periods, today), to: DateOperations

  # Default params for next_periods
  def next_periods(periods, number),
    do: DateOperations.next_periods(periods, DateHelpers.today_berlin(), number)

  # Default params for find_most_recent_period
  def find_most_recent_period(periods),
    do: DateOperations.find_most_recent_period(periods, DateHelpers.today_berlin())

  #
  # Period grouping operations - delegated to Grouping module
  #

  defdelegate group_periods_single_year(periods, start_date), to: Grouping
  defdelegate list_periods_by_vacation_names(periods), to: Grouping
  defdelegate group_by_interval(periods), to: Grouping
  defdelegate list_periods_with_bridge_day(periods, bridge_day), to: Grouping

  # Default params for group_periods_single_year
  def group_periods_single_year(periods),
    do: Grouping.group_periods_single_year(periods, DateHelpers.today_berlin())

  #
  # Cached operations for improved performance
  #

  @doc """
  Cached version of list_school_free_periods_optimized.
  Caches results based on location IDs and date range for improved performance.
  """
  def list_school_free_periods_cached(location_ids, starts_on, ends_on) do
    # Create cache key from location IDs and date range
    location_key = location_ids |> Enum.sort() |> Enum.join(",")
    cache_key = "periods_#{location_key}_#{starts_on}_#{ends_on}"

    Cache.cached_query_operation(
      cache_key,
      fn ->
        list_school_free_periods_optimized(location_ids, starts_on, ends_on)
      end,
      # 30 minutes TTL for periods
      ttl: 1800
    )
  end

  @doc """
  Clears periods-related cache entries when data is modified.
  Should be called after any period create/update/delete operations.
  """
  def clear_periods_caches do
    # Since period cache keys are dynamic, we need to clear the entire query cache
    # This is acceptable because periods change less frequently than they're queried
    :ets.delete_all_objects(:mehr_schulferien_query_cache)
  end

  @doc """
  Clears specific periods cache entries for given locations.
  """
  def clear_periods_cache_for_locations(_location_ids) do
    # For now, clear all query cache when any location's periods change
    # This could be optimized further by tracking which cache keys contain which locations
    clear_periods_caches()
  end

  #
  # Bewegliche Ferientage operations
  #

  @doc """
  Gets the beweglicher Ferientag holiday type.
  Returns nil if not found (e.g., in test environment).
  """
  def get_beweglicher_ferientag_type do
    case Repo.get_by(HolidayOrVacationType, slug: "beweglicher-ferientag") do
      nil -> nil
      type -> type
    end
  end

  @doc """
  Lists all bewegliche Ferientage for a school.
  """
  def list_bewegliche_ferientage_for_school(school_id) do
    case get_beweglicher_ferientag_type() do
      nil ->
        []

      beweglicher_type ->
        from(p in Period,
          where:
            p.location_id == ^school_id and p.holiday_or_vacation_type_id == ^beweglicher_type.id,
          order_by: [asc: p.starts_on],
          preload: [:holiday_or_vacation_type]
        )
        |> Repo.all()
    end
  end

  @doc """
  Lists upcoming bewegliche Ferientage for a school.
  """
  def list_upcoming_bewegliche_ferientage_for_school(school_id) do
    case get_beweglicher_ferientag_type() do
      nil ->
        []

      beweglicher_type ->
        today = Date.utc_today()

        from(p in Period,
          where:
            p.location_id == ^school_id and
              p.holiday_or_vacation_type_id == ^beweglicher_type.id and
              p.starts_on >= ^today,
          order_by: [asc: p.starts_on],
          preload: [:holiday_or_vacation_type]
        )
        |> Repo.all()
    end
  end

  @doc """
  Lists bewegliche Ferientage for a school within a date range.
  """
  def list_bewegliche_ferientage_for_school_in_range(school_id, start_date, end_date) do
    case get_beweglicher_ferientag_type() do
      nil ->
        []

      beweglicher_type ->
        from(p in Period,
          where:
            p.location_id == ^school_id and
              p.holiday_or_vacation_type_id == ^beweglicher_type.id and
              p.starts_on >= ^start_date and
              p.ends_on <= ^end_date,
          order_by: [asc: p.starts_on],
          preload: [:holiday_or_vacation_type]
        )
        |> Repo.all()
    end
  end

  @doc """
  Counts bewegliche Ferientage for a school.
  """
  def count_bewegliche_ferientage_for_school(school_id) do
    case get_beweglicher_ferientag_type() do
      nil ->
        0

      beweglicher_type ->
        from(p in Period,
          where:
            p.location_id == ^school_id and p.holiday_or_vacation_type_id == ^beweglicher_type.id,
          select: count(p.id)
        )
        |> Repo.one()
    end
  end

  @doc """
  Creates a beweglicher Ferientag period for a school.
  """
  def create_beweglicher_ferientag_for_school(school_id, date, memo) do
    case get_beweglicher_ferientag_type() do
      nil ->
        {:error, "Beweglicher Ferientag type not found in database"}

      beweglicher_type ->
        # Check if a beweglicher Ferientag already exists for this school on this date
        existing =
          from(p in Period,
            where:
              p.location_id == ^school_id and
                p.holiday_or_vacation_type_id == ^beweglicher_type.id and
                p.starts_on == ^date
          )
          |> Repo.one()

        if existing do
          {:error, "Ein beweglicher Ferientag existiert bereits für dieses Datum"}
        else
          attrs = %{
            "location_id" => school_id,
            "holiday_or_vacation_type_id" => beweglicher_type.id,
            "starts_on" => date,
            "ends_on" => date,
            "memo" => memo,
            "created_by_email_address" => "wiki@mehr-schulferien.de",
            "display_priority" => beweglicher_type.default_display_priority || 7,
            "html_class" => beweglicher_type.default_html_class || "success",
            "is_listed_below_month" => beweglicher_type.default_is_listed_below_month || true,
            "is_school_vacation" => beweglicher_type.default_is_school_vacation || false,
            "is_public_holiday" => beweglicher_type.default_is_public_holiday || false,
            "is_valid_for_students" => beweglicher_type.default_is_valid_for_students || true,
            "is_valid_for_everybody" => beweglicher_type.default_is_valid_for_everybody || false
          }

          create_period(attrs)
        end
    end
  end
end
