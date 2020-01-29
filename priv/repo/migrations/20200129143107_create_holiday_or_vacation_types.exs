defmodule MehrSchulferien.Repo.Migrations.CreateHolidayOrVacationTypes do
  use Ecto.Migration

  def change do
    create table(:holiday_or_vacation_types) do
      add :name, :string
      add :colloquial, :string
      add :slug, :string
      add :default_html_class, :string
      add :default_is_listed_below_month, :boolean, default: false, null: false
      add :default_is_public_holiday, :boolean, default: false, null: false
      add :default_is_school_vacation, :boolean, default: false, null: false
      add :default_is_valid_for_everybody, :boolean, default: false, null: false
      add :default_is_valid_for_students, :boolean, default: false, null: false
      add :wikipedia_url, :string
      add :country_location_id, references(:locations, on_delete: :nothing)
      add :default_religion_id, references(:religions, on_delete: :nothing)

      timestamps()
    end

    create index(:holiday_or_vacation_types, [:country_location_id])
    create index(:holiday_or_vacation_types, [:default_religion_id])
    create unique_index(:holiday_or_vacation_types, [:name, :country_location_id])
    create unique_index(:holiday_or_vacation_types, [:slug, :country_location_id])
  end
end
