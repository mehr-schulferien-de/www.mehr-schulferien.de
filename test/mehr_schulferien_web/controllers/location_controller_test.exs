defmodule MehrSchulferienWeb.LocationControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Locations

  @create_attrs %{
    is_country: true,
    name: "Deutschland",
    code: "D"
  }
  @update_attrs %{code: "DE"}
  @invalid_attrs %{name: nil}

  describe "read location data" do
    setup [:create_location]

    test "lists all locations", %{conn: conn} do
      conn = get(conn, Routes.location_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Locations"
    end

    test "shows certain location", %{conn: conn, location: location} do
      conn = get(conn, Routes.location_path(conn, :show, location))
      assert html_response(conn, 200) =~ "Show Location"
    end
  end

  describe "renders forms" do
    test "shows form for new location", %{conn: conn} do
      conn = get(conn, Routes.location_path(conn, :new))
      assert html_response(conn, 200) =~ "New Location"
    end

    test "renders form for editing chosen location", %{conn: conn} do
      location = insert(:federal_state)
      conn = get(conn, Routes.location_path(conn, :edit, location))
      assert html_response(conn, 200) =~ "Edit Location"
    end
  end

  describe "create location" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.location_path(conn, :create), location: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.location_path(conn, :show, id)

      conn = get(conn, Routes.location_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Location"
      assert Locations.get_location!(id)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.location_path(conn, :create), location: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Location"
    end
  end

  describe "update location" do
    setup [:create_location]

    test "redirects when data is valid", %{conn: conn, location: location} do
      conn = put(conn, Routes.location_path(conn, :update, location), location: @update_attrs)
      assert redirected_to(conn) == Routes.location_path(conn, :show, location)

      conn = get(conn, Routes.location_path(conn, :show, location))
      assert html_response(conn, 200) =~ "Show Location"
      location = Locations.get_location!(location.id)
      assert location.code == "DE"
    end

    test "renders errors when data is invalid", %{conn: conn, location: location} do
      conn = put(conn, Routes.location_path(conn, :update, location), location: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Location"
    end
  end

  describe "delete location" do
    setup [:create_location]

    test "deletes chosen location", %{conn: conn, location: location} do
      conn = delete(conn, Routes.location_path(conn, :delete, location))
      assert redirected_to(conn) == Routes.location_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.location_path(conn, :show, location))
      end
    end
  end

  defp create_location(_) do
    location = insert(:federal_state)
    {:ok, location: location}
  end
end
