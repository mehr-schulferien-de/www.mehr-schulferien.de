defmodule MehrSchulferien.Repo.Migrations.CreateAirports do
  use Ecto.Migration

  def change do
    create table(:airports) do
      add :name, :string
      add :slug, :string
      add :code, :string
      add :homepage_url, :string
      add :federal_state_id, references(:federal_states, on_delete: :nothing)
      add :country_id, references(:countries, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:airports, [:slug])
    create index(:airports, [:federal_state_id])
    create index(:airports, [:country_id])
  end
end
