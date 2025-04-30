ExUnit.start()

# Make sure Phoenix is started
Application.ensure_all_started(:phoenix)
# Start the app with a running server
Application.put_env(:mehr_schulferien, MehrSchulferienWeb.Endpoint, server: true)
{:ok, _} = Application.ensure_all_started(:mehr_schulferien)

# Set up Ecto sandbox for tests
Ecto.Adapters.SQL.Sandbox.mode(MehrSchulferien.Repo, :manual)

# Explicitly start the Phoenix endpoint for tests
{:ok, _} = MehrSchulferienWeb.Endpoint.start_link()
