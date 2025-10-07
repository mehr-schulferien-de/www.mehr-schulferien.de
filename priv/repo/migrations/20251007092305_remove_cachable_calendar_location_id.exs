defmodule MehrSchulferien.Repo.Migrations.RemoveCachableCalendarLocationId do
  use Ecto.Migration

  def change do
    # Drop the foreign key constraint first
    alter table(:locations) do
      remove :cachable_calendar_location_id
    end

    # Remove from deleted_schools table as well
    alter table(:deleted_schools) do
      remove :cachable_calendar_location_id
    end
  end
end
