defmodule MehrSchulferien.Repo.Migrations.CreateZipCodeMappings do
  use Ecto.Migration

  def change do
    create table(:zip_code_mappings) do
      add :lat, :string
      add :lon, :string
      add :location_id, references(:locations, on_delete: :nothing)
      add :zip_code_id, references(:zip_codes, on_delete: :nothing)

      timestamps()
    end

    create index(:zip_code_mappings, [:location_id])
    create index(:zip_code_mappings, [:zip_code_id])
    create unique_index(:zip_code_mappings, [:location_id, :zip_code_id])
  end
end
