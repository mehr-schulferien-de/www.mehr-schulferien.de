defmodule MehrSchulferien.Repo.Migrations.CreateDeletedSchools do
  use Ecto.Migration

  def change do
    create table(:deleted_schools) do
      # Original location fields
      add :original_id, :integer, null: false
      add :name, :string, null: false
      add :slug, :string, null: false
      add :code, :string
      add :parent_location_id, :integer
      add :cachable_calendar_location_id, :integer
      add :is_country, :boolean, default: false
      add :is_federal_state, :boolean, default: false
      add :is_county, :boolean, default: false
      add :is_city, :boolean, default: false
      add :is_school, :boolean, default: true
      add :location_type, :string

      # Address fields (denormalized for backup)
      add :address_line1, :string
      add :address_street, :string
      add :address_zip_code, :string
      add :address_city, :string
      add :address_email_address, :string
      add :address_phone_number, :string
      add :address_homepage_url, :string
      add :address_school_type, :string
      add :address_official_id, :string
      add :address_lat, :float
      add :address_lon, :float

      # Deletion metadata
      add :deleted_at, :utc_datetime, null: false
      add :deleted_by_user_id, :integer
      add :deletion_reason, :text

      # Original timestamps
      add :original_inserted_at, :utc_datetime
      add :original_updated_at, :utc_datetime

      timestamps()
    end

    create index(:deleted_schools, [:original_id])
    create index(:deleted_schools, [:slug])
    create index(:deleted_schools, [:deleted_at])
  end
end
