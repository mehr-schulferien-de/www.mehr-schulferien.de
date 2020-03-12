defmodule MehrSchulferien.Maps.Address do
  use Ecto.Schema

  import Ecto.Changeset

  alias MehrSchulferien.Maps.Location

  schema "addresses" do
    field :line1, :string
    field :street, :string
    field :zip_code, :string
    field :city, :string
    field :email_address, :string
    field :phone_number, :string
    field :fax_number, :string
    field :homepage_url, :string
    field :school_type, :string
    field :official_id, :string
    field :lon, :float
    field :lat, :float

    belongs_to :school_location, Location

    timestamps()
  end

  @doc false
  def changeset(address, attrs) do
    attrs = update_attrs(attrs)

    address
    |> cast(attrs, [
      :line1,
      :street,
      :zip_code,
      :city,
      :email_address,
      :phone_number,
      :fax_number,
      :homepage_url,
      :school_type,
      :official_id,
      :lon,
      :lat,
      :school_location_id
    ])
    |> validate_required([:school_location_id])
  end

  defp update_attrs(attrs) do
    line1 = attrs["address_line1"]
    street = attrs["address_street"]
    zip_code = attrs["address_zip_code"]
    city = attrs["address_city"]
    school_type = attrs["school_type_entity"]

    Map.merge(attrs, %{
      "line1" => line1,
      "street" => street,
      "zip_code" => zip_code,
      "city" => city,
      "school_type" => school_type
    })
  end
end
