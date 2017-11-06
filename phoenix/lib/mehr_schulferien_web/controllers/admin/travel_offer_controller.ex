defmodule MehrSchulferienWeb.Admin.TravelOfferController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Ads
  alias MehrSchulferien.Ads.TravelOffer

  def index(conn, _params) do
    travel_offers = Ads.list_travel_offers()
    render(conn, "index.html", travel_offers: travel_offers)
  end

  def new(conn, _params) do
    changeset = Ads.change_travel_offer(%TravelOffer{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"travel_offer" => travel_offer_params}) do
    case Ads.create_travel_offer(travel_offer_params) do
      {:ok, travel_offer} ->
        conn
        |> put_flash(:info, "Travel offer created successfully.")
        |> redirect(to: admin_travel_offer_path(conn, :show, travel_offer))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    travel_offer = Ads.get_travel_offer!(id)
    render(conn, "show.html", travel_offer: travel_offer)
  end

  def edit(conn, %{"id" => id}) do
    travel_offer = Ads.get_travel_offer!(id)
    changeset = Ads.change_travel_offer(travel_offer)
    render(conn, "edit.html", travel_offer: travel_offer, changeset: changeset)
  end

  def update(conn, %{"id" => id, "travel_offer" => travel_offer_params}) do
    travel_offer = Ads.get_travel_offer!(id)

    case Ads.update_travel_offer(travel_offer, travel_offer_params) do
      {:ok, travel_offer} ->
        conn
        |> put_flash(:info, "Travel offer updated successfully.")
        |> redirect(to: admin_travel_offer_path(conn, :show, travel_offer))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", travel_offer: travel_offer, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    travel_offer = Ads.get_travel_offer!(id)
    {:ok, _travel_offer} = Ads.delete_travel_offer(travel_offer)

    conn
    |> put_flash(:info, "Travel offer deleted successfully.")
    |> redirect(to: admin_travel_offer_path(conn, :index))
  end
end
