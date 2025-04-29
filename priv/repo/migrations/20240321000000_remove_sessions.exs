defmodule MehrSchulferien.Repo.Migrations.RemoveSessions do
  use Ecto.Migration

  def change do
    execute "DROP TABLE IF EXISTS sessions", ""
  end
end
