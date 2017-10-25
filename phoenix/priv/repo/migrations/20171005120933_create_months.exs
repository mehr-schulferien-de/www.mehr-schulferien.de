defmodule MehrSchulferien.Repo.Migrations.CreateMonths do
  use Ecto.Migration

  def change do
    create table(:months) do
      add :value, :integer
      add :slug, :string
      add :year_id, references(:years, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:months, [:slug])
    create index(:months, [:year_id])
  end
end
