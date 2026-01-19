defmodule MehrSchulferien.Repo.Migrations.AddFullNameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :full_name, :string
    end
  end
end
