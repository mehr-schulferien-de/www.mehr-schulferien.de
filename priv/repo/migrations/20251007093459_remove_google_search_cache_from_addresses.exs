defmodule MehrSchulferien.Repo.Migrations.RemoveGoogleSearchCacheFromAddresses do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      remove :google_search_cache
      remove :google_search_cached_at
    end
  end
end
