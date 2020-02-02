defmodule MehrSchulferienWeb.ZipCodeControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Maps

  @create_attrs %{value: "17890"}
  @update_attrs %{value: "17891"}
  @invalid_attrs %{value: nil}

  describe "index" do
    setup [:create_zip_code]

    test "lists all zip_codes", %{conn: conn} do
      conn = get(conn, Routes.zip_code_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Zip codes"
    end

    test "shows certain zip_code", %{conn: conn, zip_code: zip_code} do
      conn = get(conn, Routes.zip_code_path(conn, :show, zip_code))
      assert html_response(conn, 200) =~ "Show Zip code"
    end
  end

  describe "renders forms" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.zip_code_path(conn, :new))
      assert html_response(conn, 200) =~ "New Zip code"
    end

    test "renders form for editing chosen zip_code", %{conn: conn} do
      zip_code = insert(:zip_code)
      conn = get(conn, Routes.zip_code_path(conn, :edit, zip_code))
      assert html_response(conn, 200) =~ "Edit Zip code"
    end
  end

  describe "create zip_code" do
    test "redirects to show when data is valid", %{conn: conn} do
      country = insert(:country)
      create_attrs = Map.put(@create_attrs, :country_location_id, country.id)
      conn = post(conn, Routes.zip_code_path(conn, :create), zip_code: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.zip_code_path(conn, :show, id)

      conn = get(conn, Routes.zip_code_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Zip code"
      assert Maps.get_zip_code!(id)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.zip_code_path(conn, :create), zip_code: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Zip code"
    end
  end

  describe "update zip_code" do
    setup [:create_zip_code]

    test "redirects when data is valid", %{conn: conn, zip_code: zip_code} do
      conn = put(conn, Routes.zip_code_path(conn, :update, zip_code), zip_code: @update_attrs)
      assert redirected_to(conn) == Routes.zip_code_path(conn, :show, zip_code)

      conn = get(conn, Routes.zip_code_path(conn, :show, zip_code))
      assert html_response(conn, 200) =~ "17891"
      zip_code = Maps.get_zip_code!(zip_code.id)
      assert zip_code.value == "17891"
    end

    test "renders errors when data is invalid", %{conn: conn, zip_code: zip_code} do
      conn = put(conn, Routes.zip_code_path(conn, :update, zip_code), zip_code: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Zip code"
    end
  end

  describe "delete zip_code" do
    setup [:create_zip_code]

    test "deletes chosen zip_code", %{conn: conn, zip_code: zip_code} do
      conn = delete(conn, Routes.zip_code_path(conn, :delete, zip_code))
      assert redirected_to(conn) == Routes.zip_code_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.zip_code_path(conn, :show, zip_code))
      end
    end
  end

  defp create_zip_code(_) do
    zip_code = insert(:zip_code)
    {:ok, zip_code: zip_code}
  end
end
