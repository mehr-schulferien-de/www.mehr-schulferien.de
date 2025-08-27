defmodule MehrSchulferien.Repo.Migrations.AddSchuelerzeitungUrlToAddresses do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add :schuelerzeitung_url, :string
    end
  end
end
