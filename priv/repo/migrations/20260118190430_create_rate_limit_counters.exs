defmodule MehrSchulferien.Repo.Migrations.CreateRateLimitCounters do
  use Ecto.Migration

  def change do
    create table(:rate_limit_counters) do
      add :key, :string, null: false
      add :count, :integer, default: 0
      add :expires_at, :utc_datetime, null: false

      timestamps()
    end

    create unique_index(:rate_limit_counters, [:key])
    create index(:rate_limit_counters, [:expires_at])
  end
end
