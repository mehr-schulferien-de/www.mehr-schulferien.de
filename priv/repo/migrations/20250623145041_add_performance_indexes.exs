defmodule MehrSchulferien.Repo.Migrations.AddPerformanceIndexes do
  use Ecto.Migration

  def change do
    # Critical performance indexes for common query patterns

    # Index for periods date range queries (most common pattern)
    create index(:periods, [:starts_on, :ends_on])

    # Composite index for periods with location filtering
    create index(:periods, [:location_id, :starts_on, :ends_on])

    # Index for periods filtering by validity flags
    create index(:periods, [:is_valid_for_students, :is_valid_for_everybody])

    # Index for periods ordering and priority
    create index(:periods, [:starts_on, :display_priority])

    # Composite index for location hierarchy queries
    create index(:locations, [:parent_location_id, :is_federal_state])
    create index(:locations, [:parent_location_id, :is_city])
    create index(:locations, [:parent_location_id, :is_school])

    # Index for location type filtering
    create index(:locations, [:is_country], where: "is_country = true")
    create index(:locations, [:is_federal_state], where: "is_federal_state = true")

    # Index for slug-based lookups by type
    create index(:locations, [:slug, :is_country], where: "is_country = true")
    create index(:locations, [:slug, :is_federal_state], where: "is_federal_state = true")
    create index(:locations, [:slug, :is_city], where: "is_city = true")
    create index(:locations, [:slug, :is_school], where: "is_school = true")
  end
end
