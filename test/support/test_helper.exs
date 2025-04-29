ExUnit.start()

Application.ensure_all_started(:wallaby)
Application.ensure_all_started(:mehr_schulferien)

Ecto.Adapters.SQL.Sandbox.mode(MehrSchulferien.Repo, :manual)
