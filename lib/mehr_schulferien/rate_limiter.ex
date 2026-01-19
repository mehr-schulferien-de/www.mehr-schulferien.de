defmodule MehrSchulferien.RateLimiter do
  @moduledoc """
  Rate limiting for wiki edits.

  Implements three tiers of rate limiting:
  - Per user per hour: 10 edits
  - All users per hour: 50 edits
  - All users per day: 250 edits

  Uses a database-backed counter system with automatic expiration.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Repo
  alias MehrSchulferien.RateLimiter.Counter

  @user_hourly_limit 10
  @global_hourly_limit 50
  @global_daily_limit 250

  @doc """
  Checks all wiki rate limits for a user.

  Returns `:ok` if within limits.
  Returns `{:error, reason}` where reason is one of:
    - `:user_hourly_limit` - User exceeded hourly limit
    - `:global_hourly_limit` - All users exceeded hourly limit
    - `:global_daily_limit` - All users exceeded daily limit
  """
  def check_wiki_limits(user_id) do
    with :ok <- check_user_hourly(user_id),
         :ok <- check_global_hourly(),
         :ok <- check_global_daily() do
      :ok
    end
  end

  @doc """
  Increments all wiki counters for a user.

  Call this after a successful wiki edit.
  """
  def increment_wiki_counters(user_id) do
    now = DateTime.utc_now()
    date = Date.utc_today()
    hour = now.hour

    # Build all keys
    user_hourly_key = user_hourly_key(user_id, date, hour)
    global_hourly_key = global_hourly_key(date, hour)
    global_daily_key = global_daily_key(date)

    # Increment all counters (creates if not exists)
    increment_counter(user_hourly_key, hourly_expiration())
    increment_counter(global_hourly_key, hourly_expiration())
    increment_counter(global_daily_key, daily_expiration())

    :ok
  end

  @doc """
  Returns the current rate limit status for a user.

  Useful for displaying remaining edits to the user.
  """
  def get_status(user_id) do
    now = DateTime.utc_now()
    date = Date.utc_today()
    hour = now.hour

    user_hourly = get_count(user_hourly_key(user_id, date, hour))
    global_hourly = get_count(global_hourly_key(date, hour))
    global_daily = get_count(global_daily_key(date))

    %{
      user_hourly: %{
        current: user_hourly,
        limit: @user_hourly_limit,
        remaining: max(0, @user_hourly_limit - user_hourly)
      },
      global_hourly: %{
        current: global_hourly,
        limit: @global_hourly_limit,
        remaining: max(0, @global_hourly_limit - global_hourly)
      },
      global_daily: %{
        current: global_daily,
        limit: @global_daily_limit,
        remaining: max(0, @global_daily_limit - global_daily)
      }
    }
  end

  @doc """
  Cleans up expired counters.

  Returns the number of deleted counters.
  """
  def cleanup_expired do
    now = DateTime.utc_now()

    {count, _} =
      from(c in Counter, where: c.expires_at < ^now)
      |> Repo.delete_all()

    count
  end

  # ============================================================================
  # Private Functions
  # ============================================================================

  defp check_user_hourly(user_id) do
    {date, hour} = current_date_and_hour()
    check_limit(user_hourly_key(user_id, date, hour), @user_hourly_limit, :user_hourly_limit)
  end

  defp check_global_hourly do
    {date, hour} = current_date_and_hour()
    check_limit(global_hourly_key(date, hour), @global_hourly_limit, :global_hourly_limit)
  end

  defp check_global_daily do
    check_limit(global_daily_key(Date.utc_today()), @global_daily_limit, :global_daily_limit)
  end

  defp check_limit(key, limit, error_reason) do
    if get_count(key) >= limit, do: {:error, error_reason}, else: :ok
  end

  defp current_date_and_hour do
    now = DateTime.utc_now()
    {Date.utc_today(), now.hour}
  end

  defp get_count(key) do
    case Repo.get_by(Counter, key: key) do
      nil -> 0
      counter -> counter.count
    end
  end

  defp increment_counter(key, expires_at) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    # Use upsert to atomically increment or create
    Repo.insert(
      %Counter{key: key, count: 1, expires_at: expires_at, inserted_at: now, updated_at: now},
      on_conflict: [inc: [count: 1], set: [updated_at: now]],
      conflict_target: :key
    )
  end

  # Key builders
  defp user_hourly_key(user_id, date, hour) do
    "wiki:user:#{user_id}:#{Date.to_iso8601(date)}:#{hour}"
  end

  defp global_hourly_key(date, hour) do
    "wiki:global:hourly:#{Date.to_iso8601(date)}:#{hour}"
  end

  defp global_daily_key(date) do
    "wiki:global:daily:#{Date.to_iso8601(date)}"
  end

  # Expiration helpers
  defp hourly_expiration do
    DateTime.utc_now()
    |> DateTime.add(2 * 60 * 60, :second)
    |> DateTime.truncate(:second)
  end

  defp daily_expiration do
    DateTime.utc_now()
    |> DateTime.add(25 * 60 * 60, :second)
    |> DateTime.truncate(:second)
  end
end
