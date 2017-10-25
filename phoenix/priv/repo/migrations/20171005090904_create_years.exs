defmodule MehrSchulferien.Repo.Migrations.CreateYears do
  use Ecto.Migration

  def change do
    create table(:years) do
      add :value, :integer
      add :slug, :string

      timestamps()
    end

    create unique_index(:years, [:value])
    create unique_index(:years, [:slug])
  end
end
