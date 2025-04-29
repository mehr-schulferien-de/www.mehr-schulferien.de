defmodule MehrSchulferien.Repo.Migrations.RemoveUsers do
  use Ecto.Migration

  def change do
    drop table(:users)
  end
end 