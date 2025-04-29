defmodule MehrSchulferien.Repo.Migrations.RemoveSessions do
  use Ecto.Migration

  def change do
    drop table(:sessions)
  end
end
