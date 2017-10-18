defmodule MehrSchulferien.Repo.Migrations.CreateCountries do
  use Ecto.Migration

  def change do
    create table(:countries) do
      add :name, :string
      add :slug, :string

      timestamps()
    end

    create unique_index(:countries, [:slug])
  end
end
