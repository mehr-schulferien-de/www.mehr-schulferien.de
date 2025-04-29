defmodule MehrSchulferien.Repo.Migrations.RemoveSessions do
  use Ecto.Migration

  def change do
    if table_exists?(:sessions) do
      drop table(:sessions)
    end
  end
end
