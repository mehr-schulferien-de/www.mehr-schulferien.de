# Start ExUnit
ExUnit.start()

# Start Phoenix endpoint for system/browser tests
Application.ensure_all_started(:wallaby)
{:ok, _} = Application.ensure_all_started(:mehr_schulferien)

# Ecto sandbox for concurrent feature tests
Ecto.Adapters.SQL.Sandbox.mode(MehrSchulferien.Repo, :manual)

# Configure and start Wallaby
Application.put_env(:wallaby, :base_url, MehrSchulferienWeb.Endpoint.url())
