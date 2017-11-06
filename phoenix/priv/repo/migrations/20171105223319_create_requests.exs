defmodule MehrSchulferien.Repo.Migrations.CreateRequests do
  use Ecto.Migration

  def change do
    create table(:requests) do
      add :referer, :string
      add :travel_offer_id, references(:travel_offers, on_delete: :nothing)

      timestamps()
    end

    create index(:requests, [:travel_offer_id])
  end
end
