ExUnit.start()

Application.ensure_all_started(:wallaby)
Application.ensure_all_started(:mehr_schulferien)

Ecto.Adapters.SQL.Sandbox.mode(MehrSchulferien.Repo, :manual)

# Explicitly start the Phoenix endpoint for Wallaby system tests
{:ok, _} = MehrSchulferienWeb.Endpoint.start_link()
