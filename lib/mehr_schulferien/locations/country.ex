defmodule MehrSchulferien.Locations.Country do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.NameSlug

  schema "countries" do
    field :name, :string
    field :slug, NameSlug.Type

    timestamps()
  end

  @doc false
  def changeset(country, attrs) do
    country
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> NameSlug.maybe_generate_slug
    |> NameSlug.unique_constraint
  end
end
