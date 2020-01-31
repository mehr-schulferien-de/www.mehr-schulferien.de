defmodule MehrSchulferien.Maps.ZipCodeMapping do
  use Ecto.Schema

  import Ecto.Changeset

  schema "zip_code_mappings" do
    field :lat, :float
    field :lon, :float

    belongs_to :location, MehrSchulferien.Maps.Location
    belongs_to :zip_code, MehrSchulferien.Maps.ZipCode

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
