defmodule MehrSchulferien.Maps.ZipCode do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.ZipCodeValueSlug

  schema "zip_codes" do
    field :slug, ZipCodeValueSlug.Type
    field :value, :string
    belongs_to :country_location, MehrSchulferien.Maps.Location

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