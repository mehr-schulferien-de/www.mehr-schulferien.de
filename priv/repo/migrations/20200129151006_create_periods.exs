defmodule MehrSchulferien.Repo.Migrations.CreatePeriods do
  use Ecto.Migration

  def change do
    create table(:periods) do
      add :starts_on, :date
      add :ends_on, :date
      add :created_by_email_address, :string
      add :html_class, :string
      add :is_listed_below_month, :boolean, default: false, null: false
      add :is_public_holiday, :boolean, default: false, null: false
      add :is_school_vacation, :boolean, default: false, null: false
      add :is_valid_for_everybody, :boolean, default: false, null: false
      add :is_valid_for_students, :boolean, default: false, null: false

      add :holiday_or_vacation_type_id,
          references(:holiday_or_vacation_types, on_delete: :delete_all)

      add :location_id, references(:locations, on_delete: :delete_all)
      add :religion_id, references(:religions, on_delete: :delete_all)

      timestamps()
    end

    create index(:periods, [:holiday_or_vacation_type_id])
    create index(:periods, [:location_id])
    create index(:periods, [:religion_id])

    create unique_index(:periods, [
             :starts_on,
             :ends_on,
             :location_id,
             :holiday_or_vacation_type_id
           ])
  end
end
