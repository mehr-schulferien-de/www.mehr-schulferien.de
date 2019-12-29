defmodule MehrSchulferien.Locations.Country do
  use Ecto.Schema
  import Ecto.Changeset

  schema "countries" do
    field :name, :string
    field :slug, :string

    timestamps()
  end

  @doc false
  def changeset(country, attrs) do
    country
    |> cast(attrs, [:name, :slug])
    |> validate_required([:name, :slug])
  end
end
