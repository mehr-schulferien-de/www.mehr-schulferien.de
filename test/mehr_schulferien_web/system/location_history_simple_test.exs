defmodule MehrSchulferienWeb.System.LocationHistorySimpleTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest
  
  alias MehrSchulferienWeb.Helpers.CookieHelpers

  describe "cookie parsing" do
    test "parses federal state cookie correctly", %{conn: conn} do
      # Test with properly formatted cookie
      conn = conn
        |> put_req_header("cookie", 
          "recent_federal_state=%7B%22id%22%3A123%2C%22slug%22%3A%22bayern%22%2C%22name%22%3A%22Bayern%22%7D"
        )
      
      recent_state = CookieHelpers.get_recent_federal_state(conn)
      assert recent_state == %{id: 123, slug: "bayern", name: "Bayern"}
    end

    test "returns nil when no federal state cookie", %{conn: conn} do
      recent_state = CookieHelpers.get_recent_federal_state(conn)
      assert recent_state == nil
    end

    test "parses cities cookie correctly", %{conn: conn} do
      conn = conn
        |> put_req_header("cookie", 
          "recent_cities=%5B%7B%22id%22%3A456%2C%22slug%22%3A%22muenchen%22%2C%22name%22%3A%22M%C3%BCnchen%22%7D%5D"
        )
      
      recent_cities = CookieHelpers.get_recent_cities(conn)
      assert recent_cities == [%{id: 456, slug: "muenchen", name: "München"}]
    end

    test "returns empty list when no cities cookie", %{conn: conn} do
      recent_cities = CookieHelpers.get_recent_cities(conn)
      assert recent_cities == []
    end
  end

  describe "home page rendering" do
    test "home page shows recent locations when cookies are present", %{conn: conn} do
      # Simulate cookies being set
      conn = conn
        |> put_req_header("cookie", 
          "recent_federal_state=%7B%22id%22%3A123%2C%22slug%22%3A%22bayern%22%2C%22name%22%3A%22Bayern%22%7D; " <>
          "recent_cities=%5B%7B%22id%22%3A456%2C%22slug%22%3A%22muenchen%22%2C%22name%22%3A%22M%C3%BCnchen%22%7D%5D; " <>
          "recent_schools=%5B%7B%22id%22%3A789%2C%22slug%22%3A%22test-schule%22%2C%22name%22%3A%22Test%20Schule%22%2C%22cityName%22%3A%22M%C3%BCnchen%22%7D%5D"
        )
      
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Check that recent locations section is displayed
      assert response =~ "Zuletzt besuchte Orte"
      assert response =~ "Bundesland:"
      assert response =~ "Bayern"
      assert response =~ "Städte:"
      assert response =~ "München"
      assert response =~ "Schulen:"
      assert response =~ "Test Schule"
    end

    test "home page does not show recent locations section without cookies", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Recent locations section should not be present
      refute response =~ "Zuletzt besuchte Orte"
    end
  end

  describe "javascript asset" do
    test "app.js is served correctly", %{conn: conn} do
      conn = get(conn, ~p"/assets/app.js")
      assert response(conn, 200)
    end
  end
end