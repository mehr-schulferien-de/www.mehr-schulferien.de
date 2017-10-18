defmodule MehrSchulferien.Locations.City do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Locations.City
  alias MehrSchulferien.Locations.ZipCodeNameSlug

  @derive {Phoenix.Param, key: :slug}
  @derive {Poison.Encoder, only: [:id, :name, :slug, :zip_code, :country_id, :federal_state_id]}
  schema "cities" do
    field :name, :string
    field :slug, ZipCodeNameSlug.Type
    field :zip_code, :string
    belongs_to :country, MehrSchulferien.Locations.Country
    belongs_to :federal_state, MehrSchulferien.Locations.FederalState

    timestamps()
  end

  @doc false
  def changeset(%City{} = city, attrs) do
    city
    |> cast(attrs, [:name, :slug, :zip_code, :country_id, :federal_state_id])
    |> ZipCodeNameSlug.set_slug
    |> validate_required([:name, :slug, :zip_code])
    |> unique_constraint(:slug)
    |> assoc_constraint(:country)
    |> assoc_constraint(:federal_state)
  end
end
