defmodule MehrSchulferienWeb.Plugs.VisitorTrackingPlugTest do
  use MehrSchulferienWeb.ConnCase
  alias MehrSchulferienWeb.Plugs.VisitorTrackingPlug

  describe "call/2" do
    setup %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{})

      {:ok, conn: conn}
    end

    test "tracks visit and sets show_ads to true for new visitor", %{conn: conn} do
      conn = VisitorTrackingPlug.call(conn, [])

      # Should track the visit
      assert conn.resp_cookies["visitor_tracking"] != nil

      # Should set show_ads to true for new visitors
      assert conn.assigns.show_ads == true
      assert get_session(conn, :show_ads) == true
    end

    test "sets show_ads to false for returning visitor within timeframe", %{conn: conn} do
      # Set a cookie for a visitor who visited 2 hours ago
      now = System.system_time(:second)
      two_hours_ago = now - 7200
      cookie_value = "#{two_hours_ago}:#{two_hours_ago}"

      conn =
        conn
        |> put_req_cookie("visitor_tracking", cookie_value)
        |> VisitorTrackingPlug.call([])

      # Should update the visit time
      assert conn.resp_cookies["visitor_tracking"] != nil

      # Should set show_ads to false
      assert conn.assigns.show_ads == false
      assert get_session(conn, :show_ads) == false
    end

    test "sets show_ads to true for visitor within last hour", %{conn: conn} do
      # Set a cookie for a visitor who visited 30 minutes ago
      now = System.system_time(:second)
      thirty_minutes_ago = now - 1800
      cookie_value = "#{thirty_minutes_ago}:#{thirty_minutes_ago}"

      conn =
        conn
        |> put_req_cookie("visitor_tracking", cookie_value)
        |> VisitorTrackingPlug.call([])

      # Should update the visit time
      assert conn.resp_cookies["visitor_tracking"] != nil

      # Should set show_ads to true
      assert conn.assigns.show_ads == true
      assert get_session(conn, :show_ads) == true
    end

    test "sets show_ads to true for visitor after 3 months", %{conn: conn} do
      # Set a cookie for a visitor who visited 4 months ago
      now = System.system_time(:second)
      four_months_ago = now - 120 * 24 * 3600
      cookie_value = "#{four_months_ago}:#{four_months_ago}"

      conn =
        conn
        |> put_req_cookie("visitor_tracking", cookie_value)
        |> VisitorTrackingPlug.call([])

      # Should update the visit time
      assert conn.resp_cookies["visitor_tracking"] != nil

      # Should set show_ads to true
      assert conn.assigns.show_ads == true
      assert get_session(conn, :show_ads) == true
    end
  end
end
