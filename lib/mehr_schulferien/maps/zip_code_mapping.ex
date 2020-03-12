defmodule MehrSchulferien.Maps.ZipCodeMapping do
  use Ecto.Schema

  import Ecto.Changeset

  alias MehrSchulferien.Maps.{Location, ZipCode}

  schema "zip_code_mappings" do
    field :lat, :float
    field :lon, :float

    belongs_to :location, Location
    belongs_to :zip_code, ZipCode

    timestamps()
  end

  @doc false
  def changeset(zip_code_mapping, attrs) do
    zip_code_mapping
    |> cast(attrs, [:location_id, :zip_code_id, :lat, :lon])
    |> validate_required([:location_id, :zip_code_id])
    |> assoc_constraint(:location)
    |> assoc_constraint(:zip_code)
  end
end
