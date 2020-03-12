defmodule MehrSchulferien.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:addresses) do
      add :line1, :string
      add :street, :string
      add :zip_code, :string
      add :city, :string
      add :email_address, :string
      add :phone_number, :string
      add :fax_number, :string
      add :homepage_url, :string
      add :school_type, :string
      add :official_id, :string
      add :lon, :float
      add :lat, :float
      add :school_location_id, references(:locations, on_delete: :delete_all)

      timestamps()
    end
  end
end
