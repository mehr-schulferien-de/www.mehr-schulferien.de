defmodule MehrSchulferienWeb.TravelOfferControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Ads

  @create_attrs %{ad_middleman: "some ad_middleman", destination_name: "some destination_name", duration: 42, expires_on: ~D[2010-04-17], image_url: "some image_url", product_link: "some product_link", product_name: "some product_name", product_price: "120.5", tour_operator: "some tour_operator"}
  @update_attrs %{ad_middleman: "some updated ad_middleman", destination_name: "some updated destination_name", duration: 43, expires_on: ~D[2011-05-18], image_url: "some updated image_url", product_link: "some updated product_link", product_name: "some updated product_name", product_price: "456.7", tour_operator: "some updated tour_operator"}
  @invalid_attrs %{ad_middleman: nil, destination_name: nil, duration: nil, expires_on: nil, image_url: nil, product_link: nil, product_name: nil, product_price: nil, tour_operator: nil}

  def fixture(:travel_offer) do
    {:ok, travel_offer} = Ads.create_travel_offer(@create_attrs)
    travel_offer
  end

  describe "index" do
    test "lists all travel_offers", %{conn: conn} do
      conn = get conn, admin_travel_offer_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Travel offers"
    end
  end

  describe "new travel_offer" do
    test "renders form", %{conn: conn} do
      conn = get conn, admin_travel_offer_path(conn, :new)
      assert html_response(conn, 200) =~ "New Travel offer"
    end
  end

  describe "create travel_offer" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, admin_travel_offer_path(conn, :create), travel_offer: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == admin_travel_offer_path(conn, :show, id)

      conn = get conn, admin_travel_offer_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Travel offer"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, admin_travel_offer_path(conn, :create), travel_offer: @invalid_attrs
      assert html_response(conn, 200) =~ "New Travel offer"
    end
  end

  describe "edit travel_offer" do
    setup [:create_travel_offer]

    test "renders form for editing chosen travel_offer", %{conn: conn, travel_offer: travel_offer} do
      conn = get conn, admin_travel_offer_path(conn, :edit, travel_offer)
      assert html_response(conn, 200) =~ "Edit Travel offer"
    end
  end

  describe "update travel_offer" do
    setup [:create_travel_offer]

    test "redirects when data is valid", %{conn: conn, travel_offer: travel_offer} do
      conn = put conn, admin_travel_offer_path(conn, :update, travel_offer), travel_offer: @update_attrs
      assert redirected_to(conn) == admin_travel_offer_path(conn, :show, travel_offer)

      conn = get conn, admin_travel_offer_path(conn, :show, travel_offer)
      assert html_response(conn, 200) =~ "some updated ad_middleman"
    end

    test "renders errors when data is invalid", %{conn: conn, travel_offer: travel_offer} do
      conn = put conn, admin_travel_offer_path(conn, :update, travel_offer), travel_offer: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Travel offer"
    end
  end

  describe "delete travel_offer" do
    setup [:create_travel_offer]

    test "deletes chosen travel_offer", %{conn: conn, travel_offer: travel_offer} do
      conn = delete conn, admin_travel_offer_path(conn, :delete, travel_offer)
      assert redirected_to(conn) == admin_travel_offer_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, admin_travel_offer_path(conn, :show, travel_offer)
      end
    end
  end

  defp create_travel_offer(_) do
    travel_offer = fixture(:travel_offer)
    {:ok, travel_offer: travel_offer}
  end
end
