defmodule MehrSchulferien.Maps.ZipCodeMapping do
  use Ecto.Schema
  import Ecto.Changeset

  schema "zip_code_mappings" do
    field :lat, :string
    field :lon, :string
    field :location_id, :id
    field :zip_code_id, :id

    timestamps()
  end

  @doc false
  def changeset(zip_code_mapping, attrs) do
    zip_code_mapping
    |> cast(attrs, [:lat, :lon])
    |> validate_required([:lat, :lon])
  end
end
