defmodule MehrSchulferien.Repo.Migrations.CreateSchools do
  use Ecto.Migration

  def change do
    create table(:schools) do
      add :name, :string
      add :line1, :string
      add :line2, :string
      add :street, :string
      add :zip_code, :string
      add :email_address, :string
      add :fax_number, :string
      add :phone_number, :string
      add :homepage_url, :string
      add :lat, :float
      add :lon, :float
      add :slug, :string
      add :number_of_students, :integer
      add :memo, :string
      add :city_id, references(:cities, on_delete: :nothing)
      add :federal_state_id, references(:federal_states, on_delete: :nothing)
      add :country_id, references(:countries, on_delete: :nothing)
      add :school_type_id, references(:school_types, on_delete: :nothing)

      timestamps()
    end

    create index(:schools, [:city_id])
    create index(:schools, [:federal_state_id])
    create index(:schools, [:country_id])
    create index(:schools, [:school_type_id])
    create unique_index(:schools, [:slug])
    create index(:schools, [:name])
  end
end
