defmodule MehrSchulferien.Repo.Migrations.CreateUserTokens do
  use Ecto.Migration

  def change do
    create table(:user_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token_hash, :binary, null: false
      add :context, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :used_at, :utc_datetime
      add :ip_address, :string

      timestamps()
    end

    create index(:user_tokens, [:token_hash])
    create index(:user_tokens, [:user_id])
  end
end
