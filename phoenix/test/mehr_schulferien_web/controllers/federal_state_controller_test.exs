defmodule MehrSchulferienWeb.FederalStateControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Locations

  @create_attrs %{code: "some code", name: "some name", slug: "some slug"}
  @update_attrs %{code: "some updated code", name: "some updated name", slug: "some updated slug"}
  @invalid_attrs %{code: nil, name: nil, slug: nil}

  def fixture(:federal_state) do
    {:ok, federal_state} = Locations.create_federal_state(@create_attrs)
    federal_state
  end

  describe "index" do
    test "lists all federal_states", %{conn: conn} do
      conn = get conn, federal_state_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Federal states"
    end
  end

  describe "new federal_state" do
    test "renders form", %{conn: conn} do
      conn = get conn, federal_state_path(conn, :new)
      assert html_response(conn, 200) =~ "New Federal state"
    end
  end

  describe "create federal_state" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, federal_state_path(conn, :create), federal_state: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == federal_state_path(conn, :show, id)

      conn = get conn, federal_state_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Federal state"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, federal_state_path(conn, :create), federal_state: @invalid_attrs
      assert html_response(conn, 200) =~ "New Federal state"
    end
  end

  describe "edit federal_state" do
    setup [:create_federal_state]

    test "renders form for editing chosen federal_state", %{conn: conn, federal_state: federal_state} do
      conn = get conn, federal_state_path(conn, :edit, federal_state)
      assert html_response(conn, 200) =~ "Edit Federal state"
    end
  end

  describe "update federal_state" do
    setup [:create_federal_state]

    test "redirects when data is valid", %{conn: conn, federal_state: federal_state} do
      conn = put conn, federal_state_path(conn, :update, federal_state), federal_state: @update_attrs
      assert redirected_to(conn) == federal_state_path(conn, :show, federal_state)

      conn = get conn, federal_state_path(conn, :show, federal_state)
      assert html_response(conn, 200) =~ "some updated code"
    end

    test "renders errors when data is invalid", %{conn: conn, federal_state: federal_state} do
      conn = put conn, federal_state_path(conn, :update, federal_state), federal_state: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Federal state"
    end
  end

  describe "delete federal_state" do
    setup [:create_federal_state]

    test "deletes chosen federal_state", %{conn: conn, federal_state: federal_state} do
      conn = delete conn, federal_state_path(conn, :delete, federal_state)
      assert redirected_to(conn) == federal_state_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, federal_state_path(conn, :show, federal_state)
      end
    end
  end

  defp create_federal_state(_) do
    federal_state = fixture(:federal_state)
    {:ok, federal_state: federal_state}
  end
end
