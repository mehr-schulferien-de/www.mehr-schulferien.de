defmodule MehrSchulferien.Repo.Migrations.AddCompositeIndexesForPerformance do
  use Ecto.Migration

  def change do
    # Composite index for queries filtering periods by vacation type and location
    # This helps queries like: "all summer vacations for a specific state"
    create index(:periods, [:holiday_or_vacation_type_id, :location_id])

    # Composite index for queries filtering periods by religion and location
    # This helps queries like: "all Islamic holidays in a specific city"
    create index(:periods, [:religion_id, :location_id],
             where: "religion_id IS NOT NULL",
             name: :periods_religion_location_index
           )

    # Additional composite index for date range queries with vacation type
    # This helps queries like: "all vacations of type X between dates Y and Z"
    create index(:periods, [:holiday_or_vacation_type_id, :starts_on, :ends_on],
             name: :periods_vacation_type_date_range_index
           )

    # Index for locations parent hierarchy queries (if not already exists)
    # This helps traverse_to_country and similar queries
    create index(:locations, [:parent_location_id])

    # Composite index for efficient hierarchy + type queries
    # This helps queries like: "all counties in a federal state"
    create index(:locations, [:parent_location_id, :is_county],
             where: "is_county = true",
             name: :locations_parent_counties_index
           )

    # Note: addresses table already has an index on school_location_id from the search indexes migration

    # Composite index for zip code queries on zip_code_mappings
    # This helps queries that need to find all mappings for a specific zip code efficiently
    create index(:zip_code_mappings, [:zip_code_id, :location_id],
             name: :zip_code_mappings_zip_location_index
           )
  end
end
