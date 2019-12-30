defmodule MehrSchulferien.Locations.City do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Locations
  alias MehrSchulferien.NameSlug

  schema "cities" do
    field :name, :string
    field :slug, NameSlug.Type
    belongs_to :country, Locations.Country
    belongs_to :federal_state, Locations.FederalState
    has_many :zip_codes, MehrSchulferien.Locations.ZipCode

    timestamps()
  end

  @doc false
  def changeset(city, attrs) do
    city
    |> cast(attrs, [:name, :country_id, :federal_state_id])
    |> validate_required([:name, :country_id, :federal_state_id])
    |> assoc_constraint(:country)
    |> assoc_constraint(:federal_state)
    |> NameSlug.maybe_generate_slug
    |> NameSlug.unique_constraint
  end
end
