defmodule MehrSchulferienWeb.Api.CityControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.City

  @create_attrs %{country_id: 42, federal_state_id: 42, name: "some name", slug: "some slug", zip_code: "some zip_code"}
  @update_attrs %{country_id: 43, federal_state_id: 43, name: "some updated name", slug: "some updated slug", zip_code: "some updated zip_code"}
  @invalid_attrs %{country_id: nil, federal_state_id: nil, name: nil, slug: nil, zip_code: nil}

  def fixture(:city) do
    {:ok, city} = Locations.create_city(@create_attrs)
    city
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all cities", %{conn: conn} do
      conn = get conn, api_city_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create city" do
    test "renders city when data is valid", %{conn: conn} do
      conn = post conn, api_city_path(conn, :create), city: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, api_city_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "country_id" => 42,
        "federal_state_id" => 42,
        "name" => "some name",
        "slug" => "some slug",
        "zip_code" => "some zip_code"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, api_city_path(conn, :create), city: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update city" do
    setup [:create_city]

    test "renders city when data is valid", %{conn: conn, city: %City{id: id} = city} do
      conn = put conn, api_city_path(conn, :update, city), city: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, api_city_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "country_id" => 43,
        "federal_state_id" => 43,
        "name" => "some updated name",
        "slug" => "some updated slug",
        "zip_code" => "some updated zip_code"}
    end

    test "renders errors when data is invalid", %{conn: conn, city: city} do
      conn = put conn, api_city_path(conn, :update, city), city: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete city" do
    setup [:create_city]

    test "deletes chosen city", %{conn: conn, city: city} do
      conn = delete conn, api_city_path(conn, :delete, city)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, api_city_path(conn, :show, city)
      end
    end
  end

  defp create_city(_) do
    city = fixture(:city)
    {:ok, city: city}
  end
end
