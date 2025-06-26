defmodule MehrSchulferien.Repo.Migrations.RemoveLocationTypeFromDeletedSchools do
  use Ecto.Migration

  def change do
    alter table(:deleted_schools) do
      remove :location_type
    end
  end
end
