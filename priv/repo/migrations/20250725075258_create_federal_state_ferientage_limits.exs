defmodule MehrSchulferien.Repo.Migrations.CreateFederalStateFerientageLimits do
  use Ecto.Migration

  def change do
    create table(:federal_state_ferientage_limits) do
      add :federal_state_id, references(:locations, on_delete: :delete_all), null: false
      add :school_year, :string, null: false
      add :max_bewegliche_ferientage, :integer, null: false

      timestamps()
    end

    create unique_index(:federal_state_ferientage_limits, [:federal_state_id, :school_year])
    create index(:federal_state_ferientage_limits, [:school_year])
  end
end
