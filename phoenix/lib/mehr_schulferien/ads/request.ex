defmodule MehrSchulferien.Ads.Request do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Ads.Request


  schema "requests" do
    field :referer, :string
    belongs_to :travel_offer, MehrSchulferien.Ads.TravelOffer

    timestamps()
  end

  @doc false
  def changeset(%Request{} = request, attrs) do
    request
    |> cast(attrs, [:referer, :travel_offer_id])
    |> validate_required([:travel_offer_id])
    |> assoc_constraint(:travel_offer)
  end
end
