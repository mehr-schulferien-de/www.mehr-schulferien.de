defmodule MehrSchulferien.Repo.Migrations.CreateBlacklistRemovalLogs do
  use Ecto.Migration

  def change do
    create table(:blacklist_removal_logs) do
      add :blacklist_entry_id, references(:blacklist_entries, on_delete: :restrict), null: false
      add :address_id, references(:addresses, on_delete: :nilify_all)
      add :school_location_id, references(:locations, on_delete: :nilify_all)
      add :field_name, :string, null: false
      add :original_value, :string, null: false
      add :removed_at, :utc_datetime, null: false

      timestamps()
    end

    create index(:blacklist_removal_logs, [:blacklist_entry_id])
    create index(:blacklist_removal_logs, [:school_location_id])
    create index(:blacklist_removal_logs, [:address_id])
  end
end
