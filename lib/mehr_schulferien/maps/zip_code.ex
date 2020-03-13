defmodule MehrSchulferien.Maps.ZipCode do
  use Ecto.Schema

  import Ecto.Changeset

  alias MehrSchulferien.ZipCodeValueSlug
  alias MehrSchulferien.Locations.Location

  schema "zip_codes" do
    field :slug, ZipCodeValueSlug.Type
    field :value, :string

    belongs_to :country_location, Location

    many_to_many(
      :locations,
      Location,
      join_through: "zip_code_mappings"
    )

    timestamps()
  end

  @doc false
  def changeset(zip_code, attrs) do
    zip_code
    |> cast(attrs, [:value, :slug, :country_location_id])
    |> validate_required([:value, :country_location_id])
    |> validate_length(:value, min: 4)
    |> assoc_constraint(:country_location)
    |> ZipCodeValueSlug.maybe_generate_slug()
    |> ZipCodeValueSlug.unique_constraint()
  end
end
