defmodule MehrSchulferien.Institutions.School do
  use Ecto.Schema
  import Ecto.Changeset

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
    field :slug, :string
    field :street, :string
    field :zip_code, :string
    field :city_id, :id
    field :federal_state_id, :id
    field :country_id, :id
    field :school_type_id, :id

    timestamps()
  end

  @doc false
  def changeset(school, attrs) do
    school
    |> cast(attrs, [:name, :line1, :line2, :street, :zip_code, :email_address, :fax_number, :phone_number, :homepage_url, :lat, :lon, :slug, :number_of_students, :memo])
    |> validate_required([:name, :line1, :line2, :street, :zip_code, :email_address, :fax_number, :phone_number, :homepage_url, :lat, :lon, :slug, :number_of_students, :memo])
  end
end
