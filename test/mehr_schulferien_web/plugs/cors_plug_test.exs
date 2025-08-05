defmodule MehrSchulferienWeb.Plugs.CorsPlugTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferienWeb.Plugs.CorsPlug

  describe "CORS headers" do
    test "adds CORS headers to response", %{conn: conn} do
      conn = CorsPlug.call(conn, [])

      assert get_resp_header(conn, "access-control-allow-origin") == ["*"]

      assert get_resp_header(conn, "access-control-allow-methods") == [
               "GET, POST, PUT, DELETE, OPTIONS"
             ]

      assert get_resp_header(conn, "access-control-allow-headers") == ["accept, content-type"]
      assert get_resp_header(conn, "access-control-max-age") == ["3600"]
    end

    test "handles OPTIONS preflight requests", %{conn: conn} do
      conn =
        conn
        |> Map.put(:method, "OPTIONS")
        |> CorsPlug.call([])

      assert conn.status == 200
      assert conn.halted == true
      assert conn.resp_body == ""
    end

    test "does not halt non-OPTIONS requests", %{conn: conn} do
      conn = CorsPlug.call(conn, [])

      refute conn.halted
    end
  end

  describe "API endpoints with CORS" do
    test "API v2.0 endpoints include CORS headers", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.0/locations")

      assert get_resp_header(conn, "access-control-allow-origin") == ["*"]

      assert get_resp_header(conn, "access-control-allow-methods") == [
               "GET, POST, PUT, DELETE, OPTIONS"
             ]
    end

    test "API v2.1 endpoints include CORS headers", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/federal-states")

      assert get_resp_header(conn, "access-control-allow-origin") == ["*"]

      assert get_resp_header(conn, "access-control-allow-methods") == [
               "GET, POST, PUT, DELETE, OPTIONS"
             ]
    end
  end
end
