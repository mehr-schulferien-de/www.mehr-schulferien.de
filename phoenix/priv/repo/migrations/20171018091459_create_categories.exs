defmodule MehrSchulferien.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string
      add :name_plural, :string
      add :slug, :string
      add :needs_exeat, :boolean, default: false, null: false
      add :for_students, :boolean, default: false, null: false
      add :for_anybody, :boolean, default: false, null: false
      add :is_a_religion, :boolean, default: false, null: false

      timestamps()
    end

    create unique_index(:categories, [:name])
    create unique_index(:categories, [:name_plural])
    create unique_index(:categories, [:slug])
  end
end
