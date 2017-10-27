defmodule MehrSchulferienWeb.Api.FederalStateControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.FederalState

  @create_attrs %{country_id: 42, name: "some name", slug: "some slug"}
  @update_attrs %{country_id: 43, name: "some updated name", slug: "some updated slug"}
  @invalid_attrs %{country_id: nil, name: nil, slug: nil}

  def fixture(:federal_state) do
    {:ok, federal_state} = Locations.create_federal_state(@create_attrs)
    federal_state
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all federal_states", %{conn: conn} do
      conn = get conn, api_federal_state_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create federal_state" do
    test "renders federal_state when data is valid", %{conn: conn} do
      conn = post conn, api_federal_state_path(conn, :create), federal_state: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, api_federal_state_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "country_id" => 42,
        "name" => "some name",
        "slug" => "some slug"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, api_federal_state_path(conn, :create), federal_state: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update federal_state" do
    setup [:create_federal_state]

    test "renders federal_state when data is valid", %{conn: conn, federal_state: %FederalState{id: id} = federal_state} do
      conn = put conn, api_federal_state_path(conn, :update, federal_state), federal_state: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, api_federal_state_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "country_id" => 43,
        "name" => "some updated name",
        "slug" => "some updated slug"}
    end

    test "renders errors when data is invalid", %{conn: conn, federal_state: federal_state} do
      conn = put conn, api_federal_state_path(conn, :update, federal_state), federal_state: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete federal_state" do
    setup [:create_federal_state]

    test "deletes chosen federal_state", %{conn: conn, federal_state: federal_state} do
      conn = delete conn, api_federal_state_path(conn, :delete, federal_state)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, api_federal_state_path(conn, :show, federal_state)
      end
    end
  end

  defp create_federal_state(_) do
    federal_state = fixture(:federal_state)
    {:ok, federal_state: federal_state}
  end
end
