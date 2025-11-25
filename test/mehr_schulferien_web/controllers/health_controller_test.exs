defmodule MehrSchulferienWeb.HealthControllerTest do
  use MehrSchulferienWeb.ConnCase

  describe "GET /health" do
    test "returns ok status when database is connected", %{conn: conn} do
      conn = get(conn, "/health")

      assert json_response(conn, 200) == %{
               "status" => "ok",
               "database" => "connected"
             }
    end
  end
end
