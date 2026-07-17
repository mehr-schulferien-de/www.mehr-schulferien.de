defmodule MehrSchulferien.Periods.GroupedQuery do
  @moduledoc """
  SQL-based grouping of consecutive periods.

  This module provides efficient SQL queries that group consecutive periods
  (like Bewegliche Ferientage) directly in the database, avoiding the need
  for post-processing in Elixir.
  """

  alias MehrSchulferien.Periods.Period
  alias MehrSchulferien.Repo

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
