defmodule MehrSchulferien.Repo.Migrations.CreateBlacklistEntries do
  use Ecto.Migration

  def change do
    create table(:blacklist_entries) do
      add :pattern, :string, null: false
      add :pattern_regex, :string, null: false
      add :field_type, :string, null: false
      add :reason, :text
      add :requester_name, :string, null: false
      add :requester_email, :string, null: false
      add :is_active, :boolean, default: true, null: false

      add :verification_request_id,
          references(:blacklist_verification_requests, on_delete: :restrict)

      timestamps()
    end

    create index(:blacklist_entries, [:field_type])
    create index(:blacklist_entries, [:is_active])
    create index(:blacklist_entries, [:verification_request_id])

    create unique_index(:blacklist_entries, [:pattern, :field_type],
             where: "is_active = true",
             name: :blacklist_entries_active_pattern_field_type_index
           )
  end
end
