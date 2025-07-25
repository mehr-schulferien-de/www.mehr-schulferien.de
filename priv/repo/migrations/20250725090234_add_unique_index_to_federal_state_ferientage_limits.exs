defmodule MehrSchulferien.Repo.Migrations.AddUniqueIndexToFederalStateFerientageLimits do
  use Ecto.Migration

  def change do
    create unique_index(:federal_state_ferientage_limits, [:federal_state_id, :school_year],
             name: :federal_state_ferientage_limits_state_year_unique
           )
  end
end
