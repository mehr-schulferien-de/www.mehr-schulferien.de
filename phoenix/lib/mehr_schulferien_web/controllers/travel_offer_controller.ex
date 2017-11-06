defmodule MehrSchulferienWeb.TravelOfferController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Ads
  alias MehrSchulferien.Ads.TravelOffer

  def show(conn, %{"id" => id}) do
    travel_offer = Ads.get_travel_offer!(id)
    referer = conn |> Plug.Conn.get_req_header("referer")
    {:ok, request} = Ads.create_request(%{travel_offer_id: travel_offer.id, referer: List.first(referer)})
    redirect conn, external: travel_offer.product_link
  end

end
