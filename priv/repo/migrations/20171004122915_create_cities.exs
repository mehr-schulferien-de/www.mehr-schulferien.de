defmodule MehrSchulferien.Repo.Migrations.CreateCities do
  use Ecto.Migration

  def change do
    create table(:cities) do
      add :name, :string
      add :slug, :string
      add :zip_code, :string
      add :country_id, references(:countries, on_delete: :nothing)
      add :federal_state_id, references(:federal_states, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:cities, [:slug])
    create index(:cities, [:country_id])
    create index(:cities, [:federal_state_id])
  end
end
