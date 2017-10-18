defmodule MehrSchulferien.Locations.FederalState do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Locations.FederalState
  alias MehrSchulferien.NameSlug


  @derive {Phoenix.Param, key: :slug}
  schema "federal_states" do
    field :code, :string
    field :name, :string
    field :slug, NameSlug.Type
    belongs_to :country, MehrSchulferien.Locations.Country

    timestamps()
  end

  @doc false
  def changeset(%FederalState{} = federal_state, attrs) do
    federal_state
    |> cast(attrs, [:name, :code, :slug, :country_id])
    |> NameSlug.set_slug
    |> validate_required([:name, :code, :slug])
    |> unique_constraint(:slug)
    |> unique_constraint(:code)
    |> assoc_constraint(:country)
  end
end
