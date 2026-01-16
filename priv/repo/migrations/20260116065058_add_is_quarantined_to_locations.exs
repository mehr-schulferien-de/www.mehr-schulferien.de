defmodule MehrSchulferien.Repo.Migrations.AddIsQuarantinedToLocations do
  use Ecto.Migration

  def change do
    alter table(:locations) do
      add :is_quarantined, :boolean, default: false, null: false
    end

    create index(:locations, [:is_quarantined], where: "is_school = true")
  end
end
