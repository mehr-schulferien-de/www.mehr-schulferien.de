defmodule MehrSchulferien.Locations.FederalState do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.NameSlug

  schema "federal_states" do
    field :code, :string
    field :name, :string
    field :slug, NameSlug.Type
    belongs_to :country, MehrSchulferien.Locations.Country

    timestamps()
  end

  @doc false
  def changeset(federal_state, attrs) do
    federal_state
    |> cast(attrs, [:name, :code, :country_id])
    |> validate_required([:name, :code, :country_id])
    |> assoc_constraint(:country)
    |> NameSlug.maybe_generate_slug()
    |> NameSlug.unique_constraint()
  end
end
