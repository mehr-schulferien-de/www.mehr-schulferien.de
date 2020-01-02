defmodule MehrSchulferien.Repo.Migrations.CreateSchoolTypes do
  use Ecto.Migration

  def change do
    create table(:school_types) do
      add :name, :string
      add :slug, :string

      timestamps()
    end

    create unique_index(:school_types, [:name])
    create unique_index(:school_types, [:slug])
  end
end
