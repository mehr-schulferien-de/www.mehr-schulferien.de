defmodule MehrSchulferien.Periods.GroupedQuery do
  @moduledoc """
  SQL-based grouping of consecutive periods.

  This module provides efficient SQL queries that group consecutive periods
  (like Bewegliche Ferientage) directly in the database, avoiding the need
  for post-processing in Elixir.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Repo
  alias MehrSchulferien.Periods.Period

  @doc """
  Returns school vacation periods with consecutive "Bewegliche Ferientage" grouped together.

  This uses a window function approach to identify consecutive periods and group them.
  """
  def list_grouped_school_vacation_periods(location_ids, starts_on, ends_on) do
    # First, get all periods normally
    regular_periods_query =
      from(p in Period,
        join: h in assoc(p, :holiday_or_vacation_type),
        where:
          p.location_id in ^location_ids and
            p.is_valid_for_students == true and
            p.is_school_vacation == true and
            p.ends_on >= ^starts_on and
            p.starts_on <= ^ends_on and
            h.name != "Beweglicher Ferientag",
        order_by: p.starts_on
      )

    # Get grouped Bewegliche Ferientage using a CTE
    grouped_bewegliche_query = """
    WITH consecutive_groups AS (
      SELECT 
        p.id,
        p.starts_on,
        p.ends_on,
        p.memo,
        p.location_id,
        p.holiday_or_vacation_type_id,
        p.is_public_holiday,
        p.is_school_vacation,
        p.is_valid_for_students,
        p.is_valid_for_everybody,
        p.display_priority,
        p.created_by_email_address,
        p.is_listed_below_month,
        -- Create a group identifier for consecutive dates
        p.starts_on - INTERVAL '1 day' * ROW_NUMBER() OVER (
          PARTITION BY p.location_id, p.holiday_or_vacation_type_id, COALESCE(p.memo, '')
          ORDER BY p.starts_on
        ) as group_id
      FROM periods p
      JOIN holiday_or_vacation_types h ON h.id = p.holiday_or_vacation_type_id
      WHERE 
        p.location_id = ANY($1::int[]) AND
        p.is_valid_for_students = true AND
        p.is_school_vacation = true AND
        p.ends_on >= $2 AND
        p.starts_on <= $3 AND
        h.name = 'Beweglicher Ferientag'
    )
    SELECT 
      MIN(id) as id,
      MIN(starts_on) as starts_on,
      MAX(ends_on) as ends_on,
      MIN(memo) as memo,
      MIN(location_id) as location_id,
      MIN(holiday_or_vacation_type_id) as holiday_or_vacation_type_id,
      MIN(is_public_holiday::int)::boolean as is_public_holiday,
      MIN(is_school_vacation::int)::boolean as is_school_vacation,
      MIN(is_valid_for_students::int)::boolean as is_valid_for_students,
      MIN(is_valid_for_everybody::int)::boolean as is_valid_for_everybody,
      MIN(display_priority) as display_priority,
      MIN(created_by_email_address) as created_by_email_address,
      MIN(is_listed_below_month::int)::boolean as is_listed_below_month,
      COUNT(*) as merged_count
    FROM consecutive_groups
    GROUP BY group_id, location_id, holiday_or_vacation_type_id, COALESCE(memo, '')
    """

    # Execute the grouped query
    grouped_bewegliche =
      Ecto.Adapters.SQL.query!(
        Repo,
        grouped_bewegliche_query,
        [location_ids, starts_on, ends_on]
      )
      |> Map.get(:rows)
      |> Enum.map(&row_to_period/1)

    # Get regular periods
    regular_periods = Repo.all(regular_periods_query)

    # Combine and sort
    (regular_periods ++ grouped_bewegliche)
    |> Enum.sort_by(& &1.starts_on, Date)
    |> Repo.preload([:holiday_or_vacation_type, :location])
  end

  @doc """
  Alternative approach using a simpler window function for PostgreSQL.
  Groups consecutive Bewegliche Ferientage with the same memo.
  """
  def list_grouped_school_vacation_periods_v2(location_ids, starts_on, ends_on) do
    query = """
    WITH period_data AS (
      SELECT 
        p.*,
        h.name as holiday_type_name,
        -- Detect gaps in consecutive dates (days between periods)
        CASE 
          WHEN h.name = 'Beweglicher Ferientag' THEN
            (p.starts_on - LAG(p.ends_on, 1, p.starts_on - 100) OVER (
              PARTITION BY p.location_id, p.holiday_or_vacation_type_id, COALESCE(p.memo, '')
              ORDER BY p.starts_on
            ))
          ELSE 
            100  -- Non-bewegliche periods always have a "gap"
        END as days_gap
      FROM periods p
      JOIN holiday_or_vacation_types h ON h.id = p.holiday_or_vacation_type_id
      WHERE 
        p.location_id = ANY($1::int[]) AND
        p.is_valid_for_students = true AND
        p.is_school_vacation = true AND
        p.ends_on >= $2 AND
        p.starts_on <= $3
    ),
    grouped_periods AS (
      SELECT 
        *,
        -- Create group ID based on gaps (new group when gap > 3 days)
        SUM(CASE WHEN days_gap > 3 THEN 1 ELSE 0 END) OVER (
          PARTITION BY location_id, holiday_or_vacation_type_id, COALESCE(memo, '')
          ORDER BY starts_on
        ) as group_id
      FROM period_data
    )
    SELECT 
      MIN(id) as id,
      MIN(starts_on) as starts_on,
      MAX(ends_on) as ends_on,
      MIN(memo) as memo,
      MIN(location_id) as location_id,
      MIN(holiday_or_vacation_type_id) as holiday_or_vacation_type_id,
      BOOL_OR(is_public_holiday) as is_public_holiday,
      BOOL_OR(is_school_vacation) as is_school_vacation,
      BOOL_OR(is_valid_for_students) as is_valid_for_students,
      BOOL_OR(is_valid_for_everybody) as is_valid_for_everybody,
      MIN(display_priority) as display_priority,
      MIN(created_by_email_address) as created_by_email_address,
      BOOL_OR(is_listed_below_month) as is_listed_below_month,
      MIN(religion_id) as religion_id,
      MIN(inserted_at) as inserted_at,
      MAX(updated_at) as updated_at,
      COUNT(*) as merged_count
    FROM grouped_periods
    WHERE holiday_type_name = 'Beweglicher Ferientag'
    GROUP BY location_id, holiday_or_vacation_type_id, COALESCE(memo, ''), group_id

    UNION ALL

    -- Include non-Bewegliche periods as-is
    SELECT 
      id,
      starts_on,
      ends_on,
      memo,
      location_id,
      holiday_or_vacation_type_id,
      is_public_holiday,
      is_school_vacation,
      is_valid_for_students,
      is_valid_for_everybody,
      display_priority,
      created_by_email_address,
      is_listed_below_month,
      religion_id,
      inserted_at,
      updated_at,
      1 as merged_count
    FROM period_data
    WHERE holiday_type_name != 'Beweglicher Ferientag'

    ORDER BY starts_on
    """

    result = Ecto.Adapters.SQL.query!(Repo, query, [location_ids, starts_on, ends_on])

    result.rows
    |> Enum.map(&row_to_period_full(&1, result.columns))
    |> Repo.preload([:holiday_or_vacation_type, :location])
  end

  # Helper to convert a database row to a Period struct
  defp row_to_period(row) do
    [
      id,
      starts_on,
      ends_on,
      memo,
      location_id,
      holiday_or_vacation_type_id,
      is_public_holiday,
      is_school_vacation,
      is_valid_for_students,
      is_valid_for_everybody,
      display_priority,
      created_by_email_address,
      is_listed_below_month,
      merged_count
    ] = row

    %Period{
      id: id,
      starts_on: starts_on,
      ends_on: ends_on,
      memo: memo,
      location_id: location_id,
      holiday_or_vacation_type_id: holiday_or_vacation_type_id,
      is_public_holiday: is_public_holiday,
      is_school_vacation: is_school_vacation,
      is_valid_for_students: is_valid_for_students,
      is_valid_for_everybody: is_valid_for_everybody,
      display_priority: display_priority,
      created_by_email_address: created_by_email_address,
      is_listed_below_month: is_listed_below_month
    }
    |> Map.put(:merged_count, merged_count)
  end

  defp row_to_period_full(row, columns) do
    data = Enum.zip(columns, row) |> Map.new()

    %Period{
      id: data["id"],
      starts_on: data["starts_on"],
      ends_on: data["ends_on"],
      memo: data["memo"],
      location_id: data["location_id"],
      holiday_or_vacation_type_id: data["holiday_or_vacation_type_id"],
      is_public_holiday: data["is_public_holiday"],
      is_school_vacation: data["is_school_vacation"],
      is_valid_for_students: data["is_valid_for_students"],
      is_valid_for_everybody: data["is_valid_for_everybody"],
      display_priority: data["display_priority"],
      created_by_email_address: data["created_by_email_address"],
      is_listed_below_month: data["is_listed_below_month"],
      religion_id: data["religion_id"],
      inserted_at: data["inserted_at"],
      updated_at: data["updated_at"]
    }
    |> Map.put(:merged_count, data["merged_count"])
  end
end
