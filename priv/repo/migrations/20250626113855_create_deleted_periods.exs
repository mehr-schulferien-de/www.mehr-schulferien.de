defmodule MehrSchulferien.Repo.Migrations.CreateDeletedPeriods do
  use Ecto.Migration

  def change do
    create table(:deleted_periods) do
      # Original period fields
      add :original_id, :integer, null: false
      add :holiday_or_vacation_type_id, :integer
      add :location_id, :integer
      add :starts_on, :date
      add :ends_on, :date
      add :created_by_email_address, :string
      add :html_class, :string
      add :is_listed_below_month, :boolean, default: false
      add :is_public_holiday, :boolean, default: false
      add :is_school_vacation, :boolean, default: false
      add :is_valid_for_students, :boolean, default: false
      add :is_valid_for_everybody, :boolean, default: false
      add :memo, :text
      add :display_priority, :integer, default: 10

      # Reference to deleted school
      add :deleted_school_original_id, :integer, null: false

      # Deletion metadata
      add :deleted_at, :utc_datetime, null: false
      add :deleted_by_user_id, :integer

      # Original timestamps
      add :original_inserted_at, :utc_datetime
      add :original_updated_at, :utc_datetime

      timestamps()
    end

    create index(:deleted_periods, [:original_id])
    create index(:deleted_periods, [:deleted_school_original_id])
    create index(:deleted_periods, [:deleted_at])
    create index(:deleted_periods, [:starts_on, :ends_on])
  end
end
