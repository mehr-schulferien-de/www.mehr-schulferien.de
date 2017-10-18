defmodule MehrSchulferien.Repo.Migrations.CreatePeriods do
  use Ecto.Migration

  def change do
    create table(:periods) do
      add :starts_on, :date
      add :ends_on, :date
      add :name, :string
      add :slug, :string
      add :source, :string
      add :for_anybody, :boolean, default: false, null: false
      add :for_students, :boolean, default: false, null: false
      add :needs_exeat, :boolean, default: false, null: false
      add :is_a_religion, :boolean, default: false, null: false
      add :category_id, references(:categories, on_delete: :nothing)
      add :school_id, references(:schools, on_delete: :nothing)
      add :city_id, references(:cities, on_delete: :nothing)
      add :federal_state_id, references(:federal_states, on_delete: :nothing)
      add :country_id, references(:countries, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:periods, [:slug])
    create index(:periods, [:category_id])
    create index(:periods, [:school_id])
    create index(:periods, [:city_id])
    create index(:periods, [:federal_state_id])
    create index(:periods, [:country_id])
  end
end
