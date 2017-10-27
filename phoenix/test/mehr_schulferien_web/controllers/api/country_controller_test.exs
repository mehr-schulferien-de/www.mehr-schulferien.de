defmodule MehrSchulferienWeb.Api.CountryControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.Country

  @create_attrs %{name: "some name", slug: "some slug"}
  @update_attrs %{name: "some updated name", slug: "some updated slug"}
  @invalid_attrs %{name: nil, slug: nil}

  def fixture(:country) do
    {:ok, country} = Locations.create_country(@create_attrs)
    country
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all countries", %{conn: conn} do
      conn = get conn, api_country_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create country" do
    test "renders country when data is valid", %{conn: conn} do
      conn = post conn, api_country_path(conn, :create), country: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, api_country_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "name" => "some name",
        "slug" => "some slug"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, api_country_path(conn, :create), country: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update country" do
    setup [:create_country]

    test "renders country when data is valid", %{conn: conn, country: %Country{id: id} = country} do
      conn = put conn, api_country_path(conn, :update, country), country: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, api_country_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "name" => "some updated name",
        "slug" => "some updated slug"}
    end

    test "renders errors when data is invalid", %{conn: conn, country: country} do
      conn = put conn, api_country_path(conn, :update, country), country: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete country" do
    setup [:create_country]

    test "deletes chosen country", %{conn: conn, country: country} do
      conn = delete conn, api_country_path(conn, :delete, country)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, api_country_path(conn, :show, country)
      end
    end
  end

  defp create_country(_) do
    country = fixture(:country)
    {:ok, country: country}
  end
end
