defmodule MehrSchulferien.Repo.Migrations.AddVersionsTable do
  use Ecto.Migration

  def change do
    create table(:versions) do
      add :event, :string, null: false, size: 10
      add :item_type, :string, null: false
      add :item_id, :integer
      add :item_changes, :map
      add :originator_id, :integer
      add :origin, :string, size: 50
      add :meta, :map

      add :inserted_at, :utc_datetime, null: false
    end

    create index(:versions, [:originator_id])
    create index(:versions, [:item_id, :item_type])
  end
end
