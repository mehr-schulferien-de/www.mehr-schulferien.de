defmodule MehrSchulferien.Repo.Migrations.CreateBlacklistVerificationRequests do
  use Ecto.Migration

  def change do
    create table(:blacklist_verification_requests) do
      add :full_name, :string, null: false
      add :email, :string, null: false
      add :token_hash, :string, null: false
      add :verified_at, :utc_datetime
      add :expires_at, :utc_datetime, null: false
      add :ip_address, :string
      add :user_agent, :string

      timestamps()
    end

    create index(:blacklist_verification_requests, [:token_hash])
    create index(:blacklist_verification_requests, [:email])
    create index(:blacklist_verification_requests, [:expires_at])
  end
end
