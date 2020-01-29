defmodule MehrSchulferien.Repo.Migrations.CreatePeriods do
  use Ecto.Migration

  def change do
    create table(:periods) do
      add :starts_on, :date
      add :ends_on, :date
      add :author_email_address, :string
      add :location_id, references(:locations, on_delete: :nothing)

      add :holiday_or_vacation_type_id,
          references(:holiday_or_vacation_types, on_delete: :nothing)

      timestamps()
    end

    create index(:periods, [:location_id])
    create index(:periods, [:holiday_or_vacation_type_id])
  end
end
