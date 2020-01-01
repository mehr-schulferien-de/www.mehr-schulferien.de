defmodule MehrSchulferien.Locations.ZipCode do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Locations

  schema "zip_codes" do
    field :value, :string
    belongs_to :city, Locations.City
    belongs_to :country, Locations.Country

    timestamps()
  end

  @doc false
  def changeset(zip_code, attrs) do
    zip_code
    |> cast(attrs, [:value, :city_id, :country_id])
    |> validate_required([:value, :city_id, :country_id])
    |> assoc_constraint(:city)
    |> assoc_constraint(:country)
  end
end
