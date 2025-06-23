defmodule MehrSchulferien.Repo.Migrations.AddSearchIndexes do
  use Ecto.Migration

  def change do
    # Index for searching locations by name (cities and schools)
    create index(:locations, [:name])

    # Partial indexes for more efficient searching
    # Index specifically for searching schools by name
    create index(:locations, [:name],
             where: "is_school = true",
             name: :locations_school_name_index
           )

    # Index specifically for searching cities by name
    create index(:locations, [:name], where: "is_city = true", name: :locations_city_name_index)

    # Index for zip code search in addresses table
    create index(:addresses, [:zip_code])

    # Index for school_location_id to improve JOIN performance
    create index(:addresses, [:school_location_id])

    # Index for zip code values in zip_codes table
    create index(:zip_codes, [:value])
  end
end
