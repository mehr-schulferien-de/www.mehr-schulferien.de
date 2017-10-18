defmodule MehrSchulferien.Locations.School do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.School
  alias MehrSchulferien.Locations.ZipCodeNameSlug


  @derive {Phoenix.Param, key: :slug}
  schema "schools" do
    field :address_city, :string
    field :address_line1, :string
    field :address_line2, :string
    field :address_street, :string
    field :address_zip_code, :string
    field :email_address, :string
    field :fax_number, :string
    field :homepage_url, :string
    field :name, :string
    field :phone_number, :string
    field :slug, ZipCodeNameSlug.Type
    belongs_to :city, MehrSchulferien.Locations.City
    belongs_to :federal_state, MehrSchulferien.Locations.FederalState
    belongs_to :country, MehrSchulferien.Locations.Country

    timestamps()
  end

  @doc false
  def changeset(%School{} = school, attrs) do
    school
    |> cast(attrs, [:name, :slug, :address_line1, :address_line2, :address_street, :address_zip_code, :address_city, :email_address, :phone_number, :fax_number, :homepage_url, :city_id, :federal_state_id, :country_id])
    |> ZipCodeNameSlug.set_slug
    |> set_address_zip_code
    |> validate_required([:name, :slug, :address_line1, :address_zip_code, :address_city])
    |> unique_constraint(:slug)
    |> assoc_constraint(:country)
    |> assoc_constraint(:federal_state)
    |> assoc_constraint(:city)
  end

  defp set_address_zip_code(changeset) do
    address_zip_code = get_field(changeset, :address_zip_code)
    city_id = get_field(changeset, :city_id)

    case address_zip_code do
      nil -> case Locations.get_city!(city_id) do
               {:ok, city} -> put_change(changeset, :address_zip_code, city.zip_code)
               _ -> changeset
             end
      _ -> changeset
    end
  end
end
