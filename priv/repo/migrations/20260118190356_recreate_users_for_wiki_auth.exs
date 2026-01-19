defmodule MehrSchulferien.Repo.Migrations.RecreateUsersForWikiAuth do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :confirmed_at, :utc_datetime
      add :banned_at, :utc_datetime
      add :ban_reason, :string

      timestamps()
    end

    create unique_index(:users, ["lower(email)"], name: :users_email_index)
  end
end
