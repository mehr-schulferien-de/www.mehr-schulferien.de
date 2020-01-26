defmodule MehrSchulferien.Repo.Migrations.CreateLocations do
  use Ecto.Migration

  def change do
    create table(:locations) do
      add :name, :string
      add :slug, :string
      add :is_country, :boolean, default: false, null: false
      add :is_federal_state, :boolean, default: false, null: false
      add :is_county, :boolean, default: false, null: false
      add :is_city, :boolean, default: false, null: false
      add :is_school, :boolean, default: false, null: false
      add :parent_location_id, references(:locations, on_delete: :nothing)
      add :cachable_calendar_location_id, references(:locations, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:locations, [:slug, :is_country, :is_federal_state, :is_county, :is_city, :is_school])
  end
end
