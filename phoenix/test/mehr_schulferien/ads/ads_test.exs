defmodule MehrSchulferien.AdsTest do
  use MehrSchulferien.DataCase

  alias MehrSchulferien.Ads

  describe "travel_offers" do
    alias MehrSchulferien.Ads.TravelOffer

    @valid_attrs %{ad_middleman: "some ad_middleman", destination_name: "some destination_name", duration: 42, expires_on: ~D[2010-04-17], image_url: "some image_url", product_link: "some product_link", product_name: "some product_name", product_price: "120.5", tour_operator: "some tour_operator"}
    @update_attrs %{ad_middleman: "some updated ad_middleman", destination_name: "some updated destination_name", duration: 43, expires_on: ~D[2011-05-18], image_url: "some updated image_url", product_link: "some updated product_link", product_name: "some updated product_name", product_price: "456.7", tour_operator: "some updated tour_operator"}
    @invalid_attrs %{ad_middleman: nil, destination_name: nil, duration: nil, expires_on: nil, image_url: nil, product_link: nil, product_name: nil, product_price: nil, tour_operator: nil}

    def travel_offer_fixture(attrs \\ %{}) do
      {:ok, travel_offer} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Ads.create_travel_offer()

      travel_offer
    end

    test "list_travel_offers/0 returns all travel_offers" do
      travel_offer = travel_offer_fixture()
      assert Ads.list_travel_offers() == [travel_offer]
    end

    test "get_travel_offer!/1 returns the travel_offer with given id" do
      travel_offer = travel_offer_fixture()
      assert Ads.get_travel_offer!(travel_offer.id) == travel_offer
    end

    test "create_travel_offer/1 with valid data creates a travel_offer" do
      assert {:ok, %TravelOffer{} = travel_offer} = Ads.create_travel_offer(@valid_attrs)
      assert travel_offer.ad_middleman == "some ad_middleman"
      assert travel_offer.destination_name == "some destination_name"
      assert travel_offer.duration == 42
      assert travel_offer.expires_on == ~D[2010-04-17]
      assert travel_offer.image_url == "some image_url"
      assert travel_offer.product_link == "some product_link"
      assert travel_offer.product_name == "some product_name"
      assert travel_offer.product_price == Decimal.new("120.5")
      assert travel_offer.tour_operator == "some tour_operator"
    end

    test "create_travel_offer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Ads.create_travel_offer(@invalid_attrs)
    end

    test "update_travel_offer/2 with valid data updates the travel_offer" do
      travel_offer = travel_offer_fixture()
      assert {:ok, travel_offer} = Ads.update_travel_offer(travel_offer, @update_attrs)
      assert %TravelOffer{} = travel_offer
      assert travel_offer.ad_middleman == "some updated ad_middleman"
      assert travel_offer.destination_name == "some updated destination_name"
      assert travel_offer.duration == 43
      assert travel_offer.expires_on == ~D[2011-05-18]
      assert travel_offer.image_url == "some updated image_url"
      assert travel_offer.product_link == "some updated product_link"
      assert travel_offer.product_name == "some updated product_name"
      assert travel_offer.product_price == Decimal.new("456.7")
      assert travel_offer.tour_operator == "some updated tour_operator"
    end

    test "update_travel_offer/2 with invalid data returns error changeset" do
      travel_offer = travel_offer_fixture()
      assert {:error, %Ecto.Changeset{}} = Ads.update_travel_offer(travel_offer, @invalid_attrs)
      assert travel_offer == Ads.get_travel_offer!(travel_offer.id)
    end

    test "delete_travel_offer/1 deletes the travel_offer" do
      travel_offer = travel_offer_fixture()
      assert {:ok, %TravelOffer{}} = Ads.delete_travel_offer(travel_offer)
      assert_raise Ecto.NoResultsError, fn -> Ads.get_travel_offer!(travel_offer.id) end
    end

    test "change_travel_offer/1 returns a travel_offer changeset" do
      travel_offer = travel_offer_fixture()
      assert %Ecto.Changeset{} = Ads.change_travel_offer(travel_offer)
    end
  end

  describe "requests" do
    alias MehrSchulferien.Ads.Request

    @valid_attrs %{referer: "some referer"}
    @update_attrs %{referer: "some updated referer"}
    @invalid_attrs %{referer: nil}

    def request_fixture(attrs \\ %{}) do
      {:ok, request} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Ads.create_request()

      request
    end

    test "list_requests/0 returns all requests" do
      request = request_fixture()
      assert Ads.list_requests() == [request]
    end

    test "get_request!/1 returns the request with given id" do
      request = request_fixture()
      assert Ads.get_request!(request.id) == request
    end

    test "create_request/1 with valid data creates a request" do
      assert {:ok, %Request{} = request} = Ads.create_request(@valid_attrs)
      assert request.referer == "some referer"
    end

    test "create_request/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Ads.create_request(@invalid_attrs)
    end

    test "update_request/2 with valid data updates the request" do
      request = request_fixture()
      assert {:ok, request} = Ads.update_request(request, @update_attrs)
      assert %Request{} = request
      assert request.referer == "some updated referer"
    end

    test "update_request/2 with invalid data returns error changeset" do
      request = request_fixture()
      assert {:error, %Ecto.Changeset{}} = Ads.update_request(request, @invalid_attrs)
      assert request == Ads.get_request!(request.id)
    end

    test "delete_request/1 deletes the request" do
      request = request_fixture()
      assert {:ok, %Request{}} = Ads.delete_request(request)
      assert_raise Ecto.NoResultsError, fn -> Ads.get_request!(request.id) end
    end

    test "change_request/1 returns a request changeset" do
      request = request_fixture()
      assert %Ecto.Changeset{} = Ads.change_request(request)
    end
  end
end
