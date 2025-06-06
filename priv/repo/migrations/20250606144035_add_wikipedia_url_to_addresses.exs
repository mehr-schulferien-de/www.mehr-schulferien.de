defmodule MehrSchulferien.Repo.Migrations.AddWikipediaUrlToAddresses do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add :wikipedia_url, :string
    end
  end
end
