# Start ExUnit
ExUnit.start()

# Start Phoenix endpoint for system/browser tests
{:ok, _} = Application.ensure_all_started(:mehr_schulferien)

# Ecto sandbox for concurrent feature tests
Ecto.Adapters.SQL.Sandbox.mode(MehrSchulferien.Repo, :manual)
