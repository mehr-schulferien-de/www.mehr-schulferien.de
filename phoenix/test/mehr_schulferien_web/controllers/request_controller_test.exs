defmodule MehrSchulferienWeb.RequestControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Ads

  @create_attrs %{referer: "some referer"}
  @update_attrs %{referer: "some updated referer"}
  @invalid_attrs %{referer: nil}

  def fixture(:request) do
    {:ok, request} = Ads.create_request(@create_attrs)
    request
  end

  describe "index" do
    test "lists all requests", %{conn: conn} do
      conn = get conn, admin_request_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Requests"
    end
  end

  describe "new request" do
    test "renders form", %{conn: conn} do
      conn = get conn, admin_request_path(conn, :new)
      assert html_response(conn, 200) =~ "New Request"
    end
  end

  describe "create request" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, admin_request_path(conn, :create), request: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == admin_request_path(conn, :show, id)

      conn = get conn, admin_request_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Request"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, admin_request_path(conn, :create), request: @invalid_attrs
      assert html_response(conn, 200) =~ "New Request"
    end
  end

  describe "edit request" do
    setup [:create_request]

    test "renders form for editing chosen request", %{conn: conn, request: request} do
      conn = get conn, admin_request_path(conn, :edit, request)
      assert html_response(conn, 200) =~ "Edit Request"
    end
  end

  describe "update request" do
    setup [:create_request]

    test "redirects when data is valid", %{conn: conn, request: request} do
      conn = put conn, admin_request_path(conn, :update, request), request: @update_attrs
      assert redirected_to(conn) == admin_request_path(conn, :show, request)

      conn = get conn, admin_request_path(conn, :show, request)
      assert html_response(conn, 200) =~ "some updated referer"
    end

    test "renders errors when data is invalid", %{conn: conn, request: request} do
      conn = put conn, admin_request_path(conn, :update, request), request: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Request"
    end
  end

  describe "delete request" do
    setup [:create_request]

    test "deletes chosen request", %{conn: conn, request: request} do
      conn = delete conn, admin_request_path(conn, :delete, request)
      assert redirected_to(conn) == admin_request_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, admin_request_path(conn, :show, request)
      end
    end
  end

  defp create_request(_) do
    request = fixture(:request)
    {:ok, request: request}
  end
end
