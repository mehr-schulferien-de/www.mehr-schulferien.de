defmodule MehrSchulferien.Repo.Migrations.AddDescriptionToAddresses do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add :description, :text
    end
  end
end
