defmodule MehrSchulferienWeb.ZipCodeMappingControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Maps

  @create_attrs %{lat: 5.2, lon: 10.5}
  @update_attrs %{lon: 10.4}
  @invalid_attrs %{location_id: nil}

  describe "read zip_code_mapping data" do
    setup [:create_zip_code_mapping]

    test "lists all zip_code_mappings", %{conn: conn} do
      conn = get(conn, Routes.zip_code_mapping_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Zip code mappings"
    end

    test "shows certain zip_code_mapping", %{conn: conn, zip_code_mapping: zip_code_mapping} do
      conn = get(conn, Routes.zip_code_mapping_path(conn, :show, zip_code_mapping))
      assert html_response(conn, 200) =~ "Show Zip code mapping"
    end
  end

  describe "renders forms" do
    test "shows form for new zip_code_mapping", %{conn: conn} do
      conn = get(conn, Routes.zip_code_mapping_path(conn, :new))
      assert html_response(conn, 200) =~ "New Zip code mapping"
    end

    test "shows form for editing chosen zip_code_mapping", %{conn: conn} do
      zip_code_mapping = insert(:zip_code_mapping)
      conn = get(conn, Routes.zip_code_mapping_path(conn, :edit, zip_code_mapping))
      assert html_response(conn, 200) =~ "Edit Zip code mapping"
    end
  end

  describe "create zip_code_mapping" do
    test "redirects to show when data is valid", %{conn: conn} do
      location = insert(:location)
      zip_code = insert(:zip_code)

      create_attrs =
        Map.merge(@create_attrs, %{location_id: location.id, zip_code_id: zip_code.id})

      conn =
        post(conn, Routes.zip_code_mapping_path(conn, :create), zip_code_mapping: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.zip_code_mapping_path(conn, :show, id)

      conn = get(conn, Routes.zip_code_mapping_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Zip code mapping"
      assert Maps.get_zip_code_mapping!(id)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.zip_code_mapping_path(conn, :create), zip_code_mapping: @invalid_attrs)

      assert html_response(conn, 200) =~ "New Zip code mapping"
    end
  end

  describe "update zip_code_mapping" do
    setup [:create_zip_code_mapping]

    test "redirects when data is valid", %{conn: conn, zip_code_mapping: zip_code_mapping} do
      conn =
        put(conn, Routes.zip_code_mapping_path(conn, :update, zip_code_mapping),
          zip_code_mapping: @update_attrs
        )

      assert redirected_to(conn) == Routes.zip_code_mapping_path(conn, :show, zip_code_mapping)

      conn = get(conn, Routes.zip_code_mapping_path(conn, :show, zip_code_mapping))
      assert html_response(conn, 200) =~ "10.4"
      zip_code_mapping = Maps.get_zip_code_mapping!(zip_code_mapping.id)
      assert zip_code_mapping.lon == 10.4
    end

    test "renders errors when data is invalid", %{conn: conn, zip_code_mapping: zip_code_mapping} do
      conn =
        put(conn, Routes.zip_code_mapping_path(conn, :update, zip_code_mapping),
          zip_code_mapping: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Zip code mapping"
    end
  end

  describe "delete zip_code_mapping" do
    setup [:create_zip_code_mapping]

    test "deletes chosen zip_code_mapping", %{conn: conn, zip_code_mapping: zip_code_mapping} do
      conn = delete(conn, Routes.zip_code_mapping_path(conn, :delete, zip_code_mapping))
      assert redirected_to(conn) == Routes.zip_code_mapping_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.zip_code_mapping_path(conn, :show, zip_code_mapping))
      end
    end
  end

  defp create_zip_code_mapping(_) do
    zip_code_mapping = insert(:zip_code_mapping)
    {:ok, zip_code_mapping: zip_code_mapping}
  end
end
