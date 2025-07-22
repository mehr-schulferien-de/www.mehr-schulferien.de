defmodule MehrSchulferien.Repo.Migrations.AddGoogleSearchCacheToAddresses do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add :google_search_cache, :map
      add :google_search_cached_at, :utc_datetime
    end
  end
end