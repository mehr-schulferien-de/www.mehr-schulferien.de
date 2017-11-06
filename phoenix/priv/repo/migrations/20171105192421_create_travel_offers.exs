defmodule MehrSchulferien.Repo.Migrations.CreateTravelOffers do
  use Ecto.Migration

  def change do
    create table(:travel_offers) do
      add :tour_operator, :string
      add :destination_name, :string
      add :product_name, :string
      add :product_price, :decimal
      add :ad_middleman, :string
      add :product_link, :string
      add :image_url, :string
      add :duration, :integer
      add :expires_on, :date
      add :airport_id, references(:airports, on_delete: :nothing)

      timestamps()
    end

  end
end
