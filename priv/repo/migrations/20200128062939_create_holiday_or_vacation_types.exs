defmodule MehrSchulferien.Repo.Migrations.CreateHolidayOrVacationTypes do
  use Ecto.Migration

  def change do
    create table(:holiday_or_vacation_types) do
      add :name, :string
      add :colloquial, :string
      add :slug, :string
      add :html_class, :string
      add :listed_below_month, :boolean, default: false, null: false
      add :school_vacation, :boolean, default: false, null: false
      add :public_holiday, :boolean, default: false, null: false
      add :valid_for_everybody, :boolean, default: false, null: false
      add :valid_for_students, :boolean, default: false, null: false
      add :needs_approval, :boolean, default: false, null: false
      add :wikipedia_url, :string
      add :display_priority, :integer
      add :religion_id, references(:religions, on_delete: :nothing)
      add :country_location_id, references(:locations, on_delete: :nothing)

      timestamps()
    end

    create index(:holiday_or_vacation_types, [:religion_id])
    create index(:holiday_or_vacation_types, [:country_location_id])
    create unique_index(:holiday_or_vacation_types, [:name, :country_location_id])
    create unique_index(:holiday_or_vacation_types, [:slug])
  end
end
