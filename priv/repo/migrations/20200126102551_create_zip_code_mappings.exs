defmodule MehrSchulferien.Repo.Migrations.CreateZipCodeMappings do
  use Ecto.Migration

  def change do
    create table(:zip_code_mappings) do
      add :lat, :float
      add :lon, :float
      add :location_id, references(:locations, on_delete: :delete_all)
      add :zip_code_id, references(:zip_codes, on_delete: :delete_all)

      timestamps()
    end

    create index(:zip_code_mappings, [:location_id])
    create index(:zip_code_mappings, [:zip_code_id])
    create unique_index(:zip_code_mappings, [:location_id, :zip_code_id])
  end
end
