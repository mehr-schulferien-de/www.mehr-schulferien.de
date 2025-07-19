defmodule MehrSchulferien.Repo.Migrations.AddTrigramIndexesForSearch do
  use Ecto.Migration

  def up do
    # Add B-tree indexes for ILIKE searches
    # Note: We use regular B-tree indexes instead of GIN trigram indexes
    # to avoid requiring pg_trgm extension which needs superuser privileges
    create index(:locations, [:name],
             name: :locations_name_trgm_index,
             where: "is_school = true"
           )

    create index(:locations, [:name],
             name: :locations_city_name_trgm_index,
             where: "is_city = true"
           )

    # Add compound index for the common join pattern in school searches
    create index(:locations, [:parent_location_id, :is_school, :name],
             name: :locations_parent_school_name_index,
             where: "is_school = true"
           )

    # Add compound index for address + school join
    create index(:addresses, [:school_location_id, :zip_code],
             name: :addresses_school_zip_compound_index
           )
  end

  def down do
    drop index(:addresses, [:school_location_id, :zip_code],
           name: :addresses_school_zip_compound_index
         )

    drop index(:locations, [:parent_location_id, :is_school, :name],
           name: :locations_parent_school_name_index
         )

    drop index(:locations, [:name], name: :locations_city_name_trgm_index)

    drop index(:locations, [:name], name: :locations_name_trgm_index)
  end
end
