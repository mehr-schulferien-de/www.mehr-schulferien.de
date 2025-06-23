# SQL Performance test 
# Run with: mix run sql_performance_test.exs

alias MehrSchulferien.Repo
import Ecto.Query

# Count queries using telemetry
defmodule QueryCounter do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  def init(count) do
    {:ok, count}
  end

  def increment do
    GenServer.cast(__MODULE__, :increment)
  end

  def get_count do
    GenServer.call(__MODULE__, :get_count)
  end

  def reset do
    GenServer.cast(__MODULE__, :reset)
  end

  def handle_cast(:increment, count) do
    {:noreply, count + 1}
  end

  def handle_cast(:reset, _count) do
    {:noreply, 0}
  end

  def handle_call(:get_count, _from, count) do
    {:reply, count, count}
  end
end

# Start the counter
{:ok, _pid} = QueryCounter.start_link(nil)

# Setup telemetry handler
:telemetry.attach(
  "sql-counter",
  [:mehr_schulferien, :repo, :query],
  fn _event, _measurements, _metadata, _config ->
    QueryCounter.increment()
  end,
  nil
)

# Test the old approach
IO.puts("Testing OLD approach (multiple queries)...")
QueryCounter.reset()
old_start = System.monotonic_time(:millisecond)

# Old way - 2 separate queries
countries = Repo.all(from l in MehrSchulferien.Locations.Location, where: l.is_country == true)

federal_states_query =
  from(fs in MehrSchulferien.Locations.Location,
    where:
      fs.is_federal_state == true and
        fs.parent_location_id in ^Enum.map(countries, & &1.id),
    order_by: fs.name
  )

federal_states = Repo.all(federal_states_query)

old_end = System.monotonic_time(:millisecond)
old_queries = QueryCounter.get_count()
old_time = old_end - old_start

IO.puts("Old approach: #{old_time}ms with #{old_queries} queries")
IO.puts("  Countries: #{length(countries)}")
IO.puts("  Federal States: #{length(federal_states)}")

# Test the new approach
IO.puts("\nTesting NEW approach (single JOIN query)...")
QueryCounter.reset()
new_start = System.monotonic_time(:millisecond)

# New way - single join query
query =
  from c in MehrSchulferien.Locations.Location,
    left_join: fs in MehrSchulferien.Locations.Location,
    on: fs.parent_location_id == c.id and fs.is_federal_state == true,
    where: c.is_country == true,
    order_by: [asc: c.name, asc: fs.name],
    select: {c, fs}

results = Repo.all(query)

# Process results
countries_with_states =
  results
  |> Enum.group_by(fn {country, _} -> country end, fn {_, state} -> state end)
  |> Enum.map(fn {country, states} ->
    valid_states = Enum.reject(states, &is_nil/1)
    {country, valid_states}
  end)

new_end = System.monotonic_time(:millisecond)
new_queries = QueryCounter.get_count()
new_time = new_end - new_start

IO.puts("New approach: #{new_time}ms with #{new_queries} queries")
IO.puts("  Countries with states: #{length(countries_with_states)}")

# Calculate improvement
improvement = Float.round((old_time - new_time) / old_time * 100, 2)
query_reduction = old_queries - new_queries

IO.puts("\n=== PERFORMANCE IMPROVEMENT ===")
IO.puts("Time saved: #{old_time - new_time}ms (#{improvement}% faster)")
IO.puts("Queries reduced: #{old_queries} → #{new_queries} (#{query_reduction} fewer queries)")
IO.puts("===============================")

# Cleanup
:telemetry.detach("sql-counter")
