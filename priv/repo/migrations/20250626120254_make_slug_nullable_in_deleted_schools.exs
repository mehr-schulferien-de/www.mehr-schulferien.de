defmodule MehrSchulferien.Repo.Migrations.MakeSlugNullableInDeletedSchools do
  use Ecto.Migration

  def change do
    alter table(:deleted_schools) do
      modify :slug, :string, null: true
    end
  end
end
