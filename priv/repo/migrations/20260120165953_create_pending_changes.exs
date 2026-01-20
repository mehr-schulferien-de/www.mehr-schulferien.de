defmodule MehrSchulferien.Repo.Migrations.CreatePendingChanges do
  use Ecto.Migration

  def change do
    create table(:pending_changes) do
      # Type of change: create_school, update_school, delete_school,
      # create_period, update_period, delete_period, etc.
      add :change_type, :string, null: false

      # JSON payload containing all change data
      add :payload, :map, null: false

      # For updates/deletes: ID of the existing record
      add :original_record_id, :integer

      # IP address of the submitter
      add :submitted_by_ip, :string

      # Status: pending, approved, rejected
      add :status, :string, null: false, default: "pending"

      # Unique tokens for magic approval/rejection links
      add :approval_token, :string, null: false
      add :rejection_token, :string, null: false

      # When the change was reviewed
      add :reviewed_at, :utc_datetime

      # Optional reviewer note
      add :reviewer_note, :text

      timestamps()
    end

    # Index for looking up by tokens (for magic links)
    create unique_index(:pending_changes, [:approval_token])
    create unique_index(:pending_changes, [:rejection_token])

    # Index for listing pending changes
    create index(:pending_changes, [:status])
    create index(:pending_changes, [:change_type])

    # Composite index for filtering by status and type
    create index(:pending_changes, [:status, :change_type])
  end
end
