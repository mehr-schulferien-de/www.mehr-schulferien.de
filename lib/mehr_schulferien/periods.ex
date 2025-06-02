defmodule MehrSchulferien.Periods do
  @moduledoc """
  The Periods context.

  This module handles all operations related to time periods in the application,
  such as holidays, vacations, and other calendar events. It provides functions
  for querying, creating, updating, and deleting periods, as well as utility
  functions for finding periods by date range and determining schooldays.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Calendars
  alias MehrSchulferien.Calendars.{DateHelpers, HolidayOrVacationType}
  alias MehrSchulferien.Periods.{Period, Query, DateOperations, Grouping}
  alias MehrSchulferien.Repo

  #
  # Basic CRUD operations
  #

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

  If `holiday_or_vacation_type_id` is provided and valid, this function will
  pre-fill several period attributes (like `html_class`, `is_public_holiday`, etc.)
  from the defaults specified in the `HolidayOrVacationType` schema. Attributes
  explicitly passed in `attrs` will override these defaults.

  The function handles two cases for `attrs` keys:
  1. String keys (typically from controllers/params).
  2. Atom keys (internal calls). The atom-keyed version normalizes to string keys
     and calls the string-keyed version.
  """
  def create_period(%{"holiday_or_vacation_type_id" => holiday_or_vacation_type_id} = attrs)
      when not is_nil(holiday_or_vacation_type_id) and holiday_or_vacation_type_id != "" do
    # Fetch the specified holiday/vacation type to get its default attributes.
    %HolidayOrVacationType{
      id: id, # Ensure we use the actual ID from the fetched type
      default_html_class: html_class,
      default_is_listed_below_month: is_listed_below_month,
      default_is_public_holiday: is_public_holiday,
      default_is_school_vacation: is_school_vacation,
      default_is_valid_for_everybody: is_valid_for_everybody,
      default_is_valid_for_students: is_valid_for_students,
      default_religion_id: religion_id,
      default_display_priority: display_priority
    } = Calendars.get_holiday_or_vacation_type!(holiday_or_vacation_type_id)

    # Prepare default attributes from the holiday type.
    # These will be overridden by any matching keys present in `attrs`.
    default_attrs_from_type = %{
      "holiday_or_vacation_type_id" => id,
      "html_class" => html_class,
      "is_listed_below_month" => is_listed_below_month,
      "is_public_holiday" => is_public_holiday,
      "is_school_vacation" => is_school_vacation,
      "is_valid_for_everybody" => is_valid_for_everybody,
      "is_valid_for_students" => is_valid_for_students,
      "religion_id" => religion_id,
      "display_priority" => display_priority
    }

    # Merge defaults with provided attributes. `attrs` takes precedence.
    final_attrs = Map.merge(default_attrs_from_type, attrs)

    %Period{}
    |> Period.changeset(final_attrs)
    |> Repo.insert()
  end

  # Handles cases where holiday_or_vacation_type_id might be an atom key,
  # or if holiday_or_vacation_type_id is present but empty string in string-keyed map
  # which was not caught by the first clause's guard.
  def create_period(%{holiday_or_vacation_type_id: holiday_or_vacation_type_id_val} = attrs)
      when is_atom(holiday_or_vacation_type_id_val) or holiday_or_vacation_type_id_val == "" do
    # Normalize atom keys to string keys for consistent processing by the main clause,
    # or proceed without defaults if holiday_or_vacation_type_id_val is an empty string.
    string_keyed_attrs = for {key, val} <- attrs, into: %{}, do: {to_string(key), val}
    create_period(string_keyed_attrs) # Re-invoke with string keys
  end

  # Fallback clause for when `holiday_or_vacation_type_id` is not present or is nil.
  # Also handles the case where the previous clause converts atom keys to string keys
  # and holiday_or_vacation_type_id was nil or not present.
  def create_period(attrs) do
    # Ensure attrs are string-keyed if they came from the atom-keyed clause,
    # otherwise, it assumes string keys if holiday_or_vacation_type_id was initially absent/nil.
    # If attrs are already string-keyed and holiday_or_vacation_type_id is missing/nil, this is a direct call.
    processed_attrs =
      if Enum.all?(attrs, fn {k, _v} -> is_binary(k) end) do
        attrs
      else
        for {key, val} <- attrs, into: %{}, do: {to_string(key), val}
      end

    %Period{}
    |> Period.changeset(processed_attrs)
    |> Repo.insert()
  end

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

  # Unused: defdelegate list_previous_periods(federal_state, holiday_or_vacation_type), to: Query
  # Unused: defdelegate list_current_and_future_periods(federal_state, holiday_or_vacation_type), to: Query
  defdelegate list_school_vacation_periods(location_ids, starts_on, ends_on), to: Query
  defdelegate list_public_everybody_periods(location_ids, starts_on, ends_on), to: Query
  defdelegate list_public_periods(location_ids, starts_on, ends_on), to: Query
  # Unused: defdelegate list_school_free_periods(location_ids, starts_on, ends_on), to: Query
  # Unused: defdelegate list_school_free_periods_for_countries(countries, starts_on, ends_on), to: Query
  defdelegate list_school_free_periods_with_preload(location_ids, starts_on, ends_on), to: Query
  defdelegate list_years_with_periods(), to: Query

  #
  # Period filtering and finding by date - delegated to DateOperations module
  #

  defdelegate find_all_periods(periods, date), to: DateOperations
  defdelegate find_next_schoolday(periods, date), to: DateOperations
  defdelegate find_periods_by_month(date, periods), to: DateOperations
  # Unused: defdelegate find_periods_for_date_range(periods, start_date, end_date), to: DateOperations
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
end
