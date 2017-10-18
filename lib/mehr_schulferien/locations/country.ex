defmodule MehrSchulferien.Locations.Country do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Locations.Country
  alias MehrSchulferien.NameSlug

  @derive {Phoenix.Param, key: :slug}
  schema "countries" do
    field :name, :string
    field :slug, NameSlug.Type

    timestamps()
  end

  @doc false
  def changeset(%Country{} = country, attrs) do
    country
    |> cast(attrs, [:name, :slug])
    |> NameSlug.set_slug
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
  end
end
