defmodule MehrSchulferienWeb.CityControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Locations

  @create_attrs %{name: "some name", slug: "some slug", zip_code: "some zip_code"}
  @update_attrs %{name: "some updated name", slug: "some updated slug", zip_code: "some updated zip_code"}
  @invalid_attrs %{name: nil, slug: nil, zip_code: nil}

  def fixture(:city) do
    {:ok, city} = Locations.create_city(@create_attrs)
    city
  end

  describe "index" do
    test "lists all cities", %{conn: conn} do
      conn = get conn, city_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Cities"
    end
  end

  describe "new city" do
    test "renders form", %{conn: conn} do
      conn = get conn, city_path(conn, :new)
      assert html_response(conn, 200) =~ "New City"
    end
  end

  describe "create city" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, city_path(conn, :create), city: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == city_path(conn, :show, id)

      conn = get conn, city_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show City"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, city_path(conn, :create), city: @invalid_attrs
      assert html_response(conn, 200) =~ "New City"
    end
  end

  describe "edit city" do
    setup [:create_city]

    test "renders form for editing chosen city", %{conn: conn, city: city} do
      conn = get conn, city_path(conn, :edit, city)
      assert html_response(conn, 200) =~ "Edit City"
    end
  end

  describe "update city" do
    setup [:create_city]

    test "redirects when data is valid", %{conn: conn, city: city} do
      conn = put conn, city_path(conn, :update, city), city: @update_attrs
      assert redirected_to(conn) == city_path(conn, :show, city)

      conn = get conn, city_path(conn, :show, city)
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, city: city} do
      conn = put conn, city_path(conn, :update, city), city: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit City"
    end
  end

  describe "delete city" do
    setup [:create_city]

    test "deletes chosen city", %{conn: conn, city: city} do
      conn = delete conn, city_path(conn, :delete, city)
      assert redirected_to(conn) == city_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, city_path(conn, :show, city)
      end
    end
  end

  defp create_city(_) do
    city = fixture(:city)
    {:ok, city: city}
  end
end
