defmodule MehrSchulferien.Repo.Migrations.CreateDailyChangeCounts do
  use Ecto.Migration

  def change do
    create table(:daily_change_counts) do
      add :date, :date, null: false
      add :count, :integer, default: 0, null: false

      timestamps()
    end

    create unique_index(:daily_change_counts, [:date])
  end
end
