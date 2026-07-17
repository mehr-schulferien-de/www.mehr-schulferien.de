defmodule MehrSchulferien.Ads.Recorder do
  @moduledoc """
  Buffers ad impression/click counts in memory and flushes them into the
  `ad_stats` day/variant counters periodically (and on shutdown), so the
  hot path — one impression per page view — never touches the database
  inside a request.

  `record/2` is a cast to the singleton name and silently does nothing
  when the Recorder is not running (the test environment does not start
  it; tests that measure start their own supervised instance).
  """

  use GenServer

  require Logger

  alias MehrSchulferien.Ads.AdStat
  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferien.Repo

  @default_flush_interval :timer.seconds(30)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Counts one event; a no-op when the Recorder is not running."
  def record(kind, variant_id) when kind in [:impressions, :clicks] and is_integer(variant_id) do
    GenServer.cast(__MODULE__, {:record, kind, variant_id})
  end

  @doc "Flushes the buffered counts to the database now (used by tests)."
  def flush_now, do: GenServer.call(__MODULE__, :flush)

  @impl true
  def init(opts) do
    # Trap exits so terminate/2 runs on a normal shutdown and the last
    # buffered counts still reach the database.
    Process.flag(:trap_exit, true)
    interval = Keyword.get(opts, :flush_interval, @default_flush_interval)
    schedule_flush(interval)
    {:ok, %{counts: %{}, interval: interval}}
  end

  @impl true
  def handle_cast({:record, kind, variant_id}, state) do
    # The Berlin day is stamped at record time, so counts buffered across
    # midnight land on the day the event happened.
    key = {DateHelpers.today_berlin(), variant_id}

    counts =
      Map.update(state.counts, key, %{kind => 1}, fn kinds ->
        Map.update(kinds, kind, 1, &(&1 + 1))
      end)

    {:noreply, %{state | counts: counts}}
  end

  @impl true
  def handle_call(:flush, _from, state) do
    {:reply, :ok, flush(state)}
  end

  @impl true
  def handle_info(:flush, state) do
    schedule_flush(state.interval)
    {:noreply, flush(state)}
  end

  @impl true
  def terminate(_reason, state) do
    flush(state)
    :ok
  end

  defp schedule_flush(interval), do: Process.send_after(self(), :flush, interval)

  defp flush(%{counts: counts} = state) when counts == %{}, do: state

  defp flush(state) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    Enum.each(state.counts, fn {{day, variant_id}, kinds} ->
      upsert(day, variant_id, kinds, now)
    end)

    %{state | counts: %{}}
  end

  defp upsert(day, variant_id, kinds, now) do
    impressions = Map.get(kinds, :impressions, 0)
    clicks = Map.get(kinds, :clicks, 0)

    row = %{
      day: day,
      variant_id: variant_id,
      impressions: impressions,
      clicks: clicks,
      inserted_at: now,
      updated_at: now
    }

    Repo.insert_all(AdStat, [row],
      on_conflict: [
        inc: [impressions: impressions, clicks: clicks],
        set: [updated_at: now]
      ],
      conflict_target: [:day, :variant_id]
    )
  rescue
    exception ->
      # Losing a flush must never take the Recorder (or a request) down;
      # the counters are best-effort statistics, not bookkeeping.
      Logger.warning("ad stats flush failed: #{Exception.message(exception)}")
  end
end
