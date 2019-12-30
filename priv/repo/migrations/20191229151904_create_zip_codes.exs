defmodule MehrSchulferien.Repo.Migrations.CreateZipCodes do
  use Ecto.Migration

  def change do
    create table(:zip_codes) do
      add :value, :string
      add :city_id, references(:cities, on_delete: :nothing)
      add :country_id, references(:countries, on_delete: :nothing)

      timestamps()
    end

    create index(:zip_codes, [:city_id])
    create index(:zip_codes, [:country_id])
  end
end
