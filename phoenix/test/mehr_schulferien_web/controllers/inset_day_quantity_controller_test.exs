defmodule MehrSchulferienWeb.InsetDayQuantityControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Timetables

  @create_attrs %{value: 42}
  @update_attrs %{value: 43}
  @invalid_attrs %{value: nil}

  def fixture(:inset_day_quantity) do
    {:ok, inset_day_quantity} = Timetables.create_inset_day_quantity(@create_attrs)
    inset_day_quantity
  end

  describe "index" do
    test "lists all inset_day_quantities", %{conn: conn} do
      conn = get conn, admin_inset_day_quantity_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Inset day quantities"
    end
  end

  describe "new inset_day_quantity" do
    test "renders form", %{conn: conn} do
      conn = get conn, admin_inset_day_quantity_path(conn, :new)
      assert html_response(conn, 200) =~ "New Inset day quantity"
    end
  end

  describe "create inset_day_quantity" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, admin_inset_day_quantity_path(conn, :create), inset_day_quantity: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == admin_inset_day_quantity_path(conn, :show, id)

      conn = get conn, admin_inset_day_quantity_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Inset day quantity"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, admin_inset_day_quantity_path(conn, :create), inset_day_quantity: @invalid_attrs
      assert html_response(conn, 200) =~ "New Inset day quantity"
    end
  end

  describe "edit inset_day_quantity" do
    setup [:create_inset_day_quantity]

    test "renders form for editing chosen inset_day_quantity", %{conn: conn, inset_day_quantity: inset_day_quantity} do
      conn = get conn, admin_inset_day_quantity_path(conn, :edit, inset_day_quantity)
      assert html_response(conn, 200) =~ "Edit Inset day quantity"
    end
  end

  describe "update inset_day_quantity" do
    setup [:create_inset_day_quantity]

    test "redirects when data is valid", %{conn: conn, inset_day_quantity: inset_day_quantity} do
      conn = put conn, admin_inset_day_quantity_path(conn, :update, inset_day_quantity), inset_day_quantity: @update_attrs
      assert redirected_to(conn) == admin_inset_day_quantity_path(conn, :show, inset_day_quantity)

      conn = get conn, admin_inset_day_quantity_path(conn, :show, inset_day_quantity)
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, inset_day_quantity: inset_day_quantity} do
      conn = put conn, admin_inset_day_quantity_path(conn, :update, inset_day_quantity), inset_day_quantity: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Inset day quantity"
    end
  end

  describe "delete inset_day_quantity" do
    setup [:create_inset_day_quantity]

    test "deletes chosen inset_day_quantity", %{conn: conn, inset_day_quantity: inset_day_quantity} do
      conn = delete conn, admin_inset_day_quantity_path(conn, :delete, inset_day_quantity)
      assert redirected_to(conn) == admin_inset_day_quantity_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, admin_inset_day_quantity_path(conn, :show, inset_day_quantity)
      end
    end
  end

  defp create_inset_day_quantity(_) do
    inset_day_quantity = fixture(:inset_day_quantity)
    {:ok, inset_day_quantity: inset_day_quantity}
  end
end
