defmodule MehrSchulferien.Repo.Migrations.CreateAdStats do
  use Ecto.Migration

  def change do
    create table(:ad_stats) do
      add :day, :date, null: false
      add :variant_id, :integer, null: false
      add :impressions, :integer, null: false, default: 0
      add :clicks, :integer, null: false, default: 0

      timestamps()
    end

    create unique_index(:ad_stats, [:day, :variant_id])
  end
end
