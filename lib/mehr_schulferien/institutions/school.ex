defmodule MehrSchulferien.Institutions.School do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.NameSlug
  alias MehrSchulferien.Locations
  alias MehrSchulferien.Institutions

  schema "schools" do
    field :email_address, :string
    field :fax_number, :string
    field :homepage_url, :string
    field :lat, :float
    field :line1, :string
    field :line2, :string
    field :lon, :float
    field :memo, :string
    field :name, :string
    field :number_of_students, :integer
    field :phone_number, :string
    field :slug, NameSlug.Type
    field :street, :string
    field :zip_code, :string
    belongs_to :school_type, Institutions.SchoolType
    belongs_to :city, Locations.City
    belongs_to :country, Locations.Country
    belongs_to :federal_state, Locations.FederalState

    timestamps()
  end

  @doc false
  def changeset(school, attrs) do
    school
    |> cast(attrs, [:name, :line1, :line2, :street, :zip_code, :email_address, :fax_number, :phone_number, :homepage_url, :lat, :lon, :number_of_students, :memo])
    |> validate_required([:name, :zip_code])
  end
end
