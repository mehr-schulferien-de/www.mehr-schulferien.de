defmodule MehrSchulferienWeb.AdVisibilityHelperTest do
  use MehrSchulferienWeb.ConnCase
  alias MehrSchulferienWeb.AdVisibilityHelper

  describe "show_ads?/1" do
    test "returns true for new visitor without cookie", %{conn: conn} do
      assert AdVisibilityHelper.show_ads?(conn) == true
    end

    test "returns true for visitor who visited within the last hour", %{conn: conn} do
      # Set a cookie with last visit 30 minutes ago
      now = System.system_time(:second)
      thirty_minutes_ago = now - 1800
      cookie_value = "#{thirty_minutes_ago}:#{thirty_minutes_ago}"

      conn = put_req_cookie(conn, "visitor_tracking", cookie_value)
      assert AdVisibilityHelper.show_ads?(conn) == true
    end

    test "returns false for visitor who visited 2 hours ago", %{conn: conn} do
      # Set a cookie with last visit 2 hours ago
      now = System.system_time(:second)
      two_hours_ago = now - 7200
      cookie_value = "#{two_hours_ago}:#{two_hours_ago}"

      conn = put_req_cookie(conn, "visitor_tracking", cookie_value)
      assert AdVisibilityHelper.show_ads?(conn) == false
    end

    test "returns false for visitor who visited 1 day ago", %{conn: conn} do
      # Set a cookie with last visit 1 day ago
      now = System.system_time(:second)
      one_day_ago = now - 86_400
      cookie_value = "#{one_day_ago}:#{one_day_ago}"

      conn = put_req_cookie(conn, "visitor_tracking", cookie_value)
      assert AdVisibilityHelper.show_ads?(conn) == false
    end

    test "returns false for visitor who visited 2 months ago", %{conn: conn} do
      # Set a cookie with last visit 2 months ago (still within 3 months)
      now = System.system_time(:second)
      two_months_ago = now - 60 * 24 * 3600
      cookie_value = "#{two_months_ago}:#{two_months_ago}"

      conn = put_req_cookie(conn, "visitor_tracking", cookie_value)
      assert AdVisibilityHelper.show_ads?(conn) == false
    end

    test "returns true for visitor who hasn't visited in over 3 months", %{conn: conn} do
      # Set a cookie with last visit 4 months ago
      now = System.system_time(:second)
      four_months_ago = now - 120 * 24 * 3600
      cookie_value = "#{four_months_ago}:#{four_months_ago}"

      conn = put_req_cookie(conn, "visitor_tracking", cookie_value)
      assert AdVisibilityHelper.show_ads?(conn) == true
    end

    test "returns true for invalid cookie format", %{conn: conn} do
      conn = put_req_cookie(conn, "visitor_tracking", "invalid_format")
      assert AdVisibilityHelper.show_ads?(conn) == true
    end

    test "returns true for cookie with non-numeric values", %{conn: conn} do
      conn = put_req_cookie(conn, "visitor_tracking", "abc:def")
      assert AdVisibilityHelper.show_ads?(conn) == true
    end
  end

  describe "track_visit/1" do
    test "sets visitor tracking cookie for new visitor", %{conn: conn} do
      conn = AdVisibilityHelper.track_visit(conn)
      assert conn.resp_cookies["visitor_tracking"] != nil

      cookie = conn.resp_cookies["visitor_tracking"]
      assert cookie.max_age == 90 * 24 * 3600
      assert cookie.http_only == true
      assert cookie.same_site == "Lax"

      # Check cookie value format
      [first, last] = String.split(cookie.value, ":")
      assert is_binary(first)
      assert is_binary(last)
      assert first == last
    end

    test "updates last visit time for returning visitor", %{conn: conn} do
      # Initial visit
      first_visit_time = System.system_time(:second) - 86_400
      cookie_value = "#{first_visit_time}:#{first_visit_time}"
      conn = put_req_cookie(conn, "visitor_tracking", cookie_value)

      # Track new visit
      conn = AdVisibilityHelper.track_visit(conn)
      new_cookie = conn.resp_cookies["visitor_tracking"]

      # Parse the new cookie
      [first, last] = String.split(new_cookie.value, ":")
      {first_timestamp, _} = Integer.parse(first)
      {last_timestamp, _} = Integer.parse(last)

      # First visit time should be preserved
      assert first_timestamp == first_visit_time
      # Last visit time should be updated
      assert last_timestamp > first_visit_time
      assert_in_delta last_timestamp, System.system_time(:second), 2
    end

    test "handles invalid cookie gracefully", %{conn: conn} do
      conn =
        conn
        |> put_req_cookie("visitor_tracking", "invalid")
        |> AdVisibilityHelper.track_visit()

      cookie = conn.resp_cookies["visitor_tracking"]
      assert cookie != nil

      # Should create new tracking cookie
      [first, last] = String.split(cookie.value, ":")
      assert first == last
    end
  end
end
