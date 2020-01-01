defmodule MehrSchulferien.Locations.City do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Locations
  alias MehrSchulferien.CitySlug

  schema "cities" do
    field :name, :string
    field :slug, CitySlug.Type
    belongs_to :country, Locations.Country
    belongs_to :federal_state, Locations.FederalState
    has_many :zip_codes, MehrSchulferien.Locations.ZipCode

    timestamps()
  end

  @doc false
  def changeset(city, attrs) do
    city
    |> cast(attrs, [:name, :country_id, :federal_state_id])
    |> put_assoc(:zip_codes, attrs[:zip_codes], required: true)
    |> validate_required([:name, :country_id, :federal_state_id])
    |> assoc_constraint(:country)
    |> assoc_constraint(:federal_state)
    |> validate_length(:zip_codes, min: 1)
    |> CitySlug.maybe_generate_slug()
    |> CitySlug.unique_constraint()
  end
end
