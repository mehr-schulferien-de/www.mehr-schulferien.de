defmodule MehrSchulferien.Repo.Migrations.CreateSchools do
  use Ecto.Migration

  def change do
    create table(:schools) do
      add :name, :string
      add :slug, :string
      add :address_line1, :string
      add :address_line2, :string
      add :address_street, :string
      add :address_zip_code, :string
      add :address_city, :string
      add :email_address, :string
      add :phone_number, :string
      add :fax_number, :string
      add :homepage_url, :string
      add :city_id, references(:cities, on_delete: :nothing)
      add :federal_state_id, references(:federal_states, on_delete: :nothing)
      add :country_id, references(:countries, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:schools, [:slug])
    create index(:schools, [:city_id])
    create index(:schools, [:federal_state_id])
    create index(:schools, [:country_id])
  end
end
