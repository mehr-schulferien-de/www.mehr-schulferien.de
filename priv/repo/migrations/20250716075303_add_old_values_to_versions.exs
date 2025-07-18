defmodule MehrSchulferien.Repo.Migrations.AddOldValuesToVersions do
  use Ecto.Migration

  def change do
    alter table(:versions) do
      add :old_values, :map
    end
  end
end
