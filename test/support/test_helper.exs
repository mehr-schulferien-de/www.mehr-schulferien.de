ExUnit.start()

# Make sure Phoenix is started
Application.ensure_all_started(:phoenix)
# Start Wallaby for system tests
Application.ensure_all_started(:wallaby)
# Start the app with a running server
Application.put_env(:mehr_schulferien, MehrSchulferienWeb.Endpoint, server: true)
{:ok, _} = Application.ensure_all_started(:mehr_schulferien)

# Set up Ecto sandbox for tests
Ecto.Adapters.SQL.Sandbox.mode(MehrSchulferien.Repo, :manual)

# Set the base URL for Wallaby
Application.put_env(:wallaby, :base_url, "http://localhost:4002")

# Explicitly start the Phoenix endpoint for Wallaby system tests
{:ok, _} = MehrSchulferienWeb.Endpoint.start_link()
