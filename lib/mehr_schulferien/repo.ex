defmodule MehrSchulferien.Repo do
  use Ecto.Repo,
    otp_app: :mehr_schulferien,
    adapter: Ecto.Adapters.Postgres
end
