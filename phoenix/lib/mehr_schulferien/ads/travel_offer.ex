defmodule MehrSchulferien.Ads.TravelOffer do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Ads.TravelOffer


  schema "travel_offers" do
    field :ad_middleman, :string
    field :destination_name, :string
    field :duration, :integer
    field :expires_on, :date
    field :image_url, :string
    field :product_link, :string
    field :product_name, :string
    field :product_price, :decimal
    field :tour_operator, :string
    belongs_to :airport, MehrSchulferien.Locations.Airport

    timestamps()
  end

  @doc false
  def changeset(%TravelOffer{} = travel_offer, attrs) do
    travel_offer
    |> cast(attrs, [:tour_operator, :destination_name, :product_name, :product_price, :ad_middleman, :product_link, :image_url, :duration, :expires_on, :airport_id])
    |> validate_required([:tour_operator, :destination_name, :product_name, :product_price, :ad_middleman, :product_link, :image_url, :duration, :expires_on])
  end
end
