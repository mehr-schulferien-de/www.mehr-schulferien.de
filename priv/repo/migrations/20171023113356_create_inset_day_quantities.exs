defmodule MehrSchulferien.Repo.Migrations.CreateInsetDayQuantities do
  use Ecto.Migration

  def change do
    create table(:inset_day_quantities) do
      add :value, :integer
      add :federal_state_id, references(:federal_states, on_delete: :nothing)
      add :year_id, references(:years, on_delete: :nothing)

      timestamps()
    end

    create index(:inset_day_quantities, [:federal_state_id])
    create index(:inset_day_quantities, [:year_id])
    create unique_index(:inset_day_quantities, [:federal_state_id, :year_id], name: :state_id_year_id)
  end
end
