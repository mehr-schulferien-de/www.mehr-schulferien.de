defmodule MehrSchulferienWeb.ZipCodeMappingControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Maps

  @create_attrs %{lat: "some lat", lon: "some lon"}
  @update_attrs %{lat: "some updated lat", lon: "some updated lon"}
  @invalid_attrs %{lat: nil, lon: nil}

  def fixture(:zip_code_mapping) do
    {:ok, zip_code_mapping} = Maps.create_zip_code_mapping(@create_attrs)
    zip_code_mapping
  end

  describe "index" do
    test "lists all zip_code_mappings", %{conn: conn} do
      conn = get(conn, Routes.zip_code_mapping_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Zip code mappings"
    end
  end

  describe "new zip_code_mapping" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.zip_code_mapping_path(conn, :new))
      assert html_response(conn, 200) =~ "New Zip code mapping"
    end
  end

  describe "create zip_code_mapping" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn =
        post(conn, Routes.zip_code_mapping_path(conn, :create), zip_code_mapping: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.zip_code_mapping_path(conn, :show, id)

      conn = get(conn, Routes.zip_code_mapping_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Zip code mapping"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.zip_code_mapping_path(conn, :create), zip_code_mapping: @invalid_attrs)

      assert html_response(conn, 200) =~ "New Zip code mapping"
    end
  end

  describe "edit zip_code_mapping" do
    setup [:create_zip_code_mapping]

    test "renders form for editing chosen zip_code_mapping", %{
      conn: conn,
      zip_code_mapping: zip_code_mapping
    } do
      conn = get(conn, Routes.zip_code_mapping_path(conn, :edit, zip_code_mapping))
      assert html_response(conn, 200) =~ "Edit Zip code mapping"
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
      assert html_response(conn, 200) =~ "some updated lat"
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
    zip_code_mapping = fixture(:zip_code_mapping)
    {:ok, zip_code_mapping: zip_code_mapping}
  end
end
