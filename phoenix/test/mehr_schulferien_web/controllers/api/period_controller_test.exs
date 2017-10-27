defmodule MehrSchulferienWeb.Api.PeriodControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Timetables
  alias MehrSchulferien.Timetables.Period

  @create_attrs %{city_id: 42, country_id: 42, ends_on: "some ends_on", federal_state_id: 42, name: "some name", slug: "some slug", starts_on: "some starts_on"}
  @update_attrs %{city_id: 43, country_id: 43, ends_on: "some updated ends_on", federal_state_id: 43, name: "some updated name", slug: "some updated slug", starts_on: "some updated starts_on"}
  @invalid_attrs %{city_id: nil, country_id: nil, ends_on: nil, federal_state_id: nil, name: nil, slug: nil, starts_on: nil}

  def fixture(:period) do
    {:ok, period} = Timetables.create_period(@create_attrs)
    period
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all periods", %{conn: conn} do
      conn = get conn, api_period_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create period" do
    test "renders period when data is valid", %{conn: conn} do
      conn = post conn, api_period_path(conn, :create), period: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, api_period_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "city_id" => 42,
        "country_id" => 42,
        "ends_on" => "some ends_on",
        "federal_state_id" => 42,
        "name" => "some name",
        "slug" => "some slug",
        "starts_on" => "some starts_on"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, api_period_path(conn, :create), period: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update period" do
    setup [:create_period]

    test "renders period when data is valid", %{conn: conn, period: %Period{id: id} = period} do
      conn = put conn, api_period_path(conn, :update, period), period: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, api_period_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "city_id" => 43,
        "country_id" => 43,
        "ends_on" => "some updated ends_on",
        "federal_state_id" => 43,
        "name" => "some updated name",
        "slug" => "some updated slug",
        "starts_on" => "some updated starts_on"}
    end

    test "renders errors when data is invalid", %{conn: conn, period: period} do
      conn = put conn, api_period_path(conn, :update, period), period: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete period" do
    setup [:create_period]

    test "deletes chosen period", %{conn: conn, period: period} do
      conn = delete conn, api_period_path(conn, :delete, period)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, api_period_path(conn, :show, period)
      end
    end
  end

  defp create_period(_) do
    period = fixture(:period)
    {:ok, period: period}
  end
end
