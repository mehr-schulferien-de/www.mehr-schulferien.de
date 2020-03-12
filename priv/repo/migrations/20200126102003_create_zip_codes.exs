defmodule MehrSchulferien.Repo.Migrations.CreateZipCodes do
  use Ecto.Migration

  def change do
    create table(:zip_codes) do
      add :value, :string
      add :slug, :string
      add :country_location_id, references(:locations, on_delete: :delete_all)

      timestamps()
    end

    create index(:zip_codes, [:country_location_id])
    create unique_index(:zip_codes, [:slug, :country_location_id])
  end
end
