defmodule MehrSchulferien.Locations.DeletedSchool do
  use Ecto.Schema
  import Ecto.Changeset

  schema "deleted_schools" do
    # Original location fields
    field :original_id, :integer
    field :name, :string
    field :slug, :string
    field :code, :string
    field :parent_location_id, :integer
    field :cachable_calendar_location_id, :integer
    field :is_country, :boolean, default: false
    field :is_federal_state, :boolean, default: false
    field :is_county, :boolean, default: false
    field :is_city, :boolean, default: false
    field :is_school, :boolean, default: true

    # Address fields (denormalized for backup)
    field :address_line1, :string
    field :address_street, :string
    field :address_zip_code, :string
    field :address_city, :string
    field :address_email_address, :string
    field :address_phone_number, :string
    field :address_homepage_url, :string
    field :address_school_type, :string
    field :address_official_id, :string
    field :address_lat, :float
    field :address_lon, :float

    # Deletion metadata
    field :deleted_at, :utc_datetime
    field :deleted_by_user_id, :integer
    field :deletion_reason, :string

    # Original timestamps
    field :original_inserted_at, :utc_datetime
    field :original_updated_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(deleted_school, attrs) do
    deleted_school
    |> cast(attrs, [
      :original_id,
      :name,
      :slug,
      :code,
      :parent_location_id,
      :cachable_calendar_location_id,
      :is_country,
      :is_federal_state,
      :is_county,
      :is_city,
      :is_school,
      :address_line1,
      :address_street,
      :address_zip_code,
      :address_city,
      :address_email_address,
      :address_phone_number,
      :address_homepage_url,
      :address_school_type,
      :address_official_id,
      :address_lat,
      :address_lon,
      :deleted_at,
      :deleted_by_user_id,
      :deletion_reason,
      :original_inserted_at,
      :original_updated_at
    ])
    |> validate_required([:original_id, :name, :deleted_at])
  end
end
