defmodule MehrSchulferienWeb.SitemapControllerTest do
  use MehrSchulferienWeb.ConnCase

  setup %{conn: conn} do
    conn = conn |> bypass_through(MehrSchulferienWeb.Router, [:browser]) |> get("/users/new")
    {:ok, %{conn: conn}}
  end

  describe "GET /sitemap.xml" do
    setup [:add_federal_state]

    test "access the sitemap in format xml", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, "/sitemap.xml")
      assert response_content_type(conn, :xml)
      assert response(conn, 200) =~ ~r/<loc>.*#{federal_state.slug}<\/loc>/
    end
  end

  defp add_federal_state(_) do
    country = insert(:country, %{slug: "d"})
    federal_state = insert(:federal_state, %{parent_location_id: country.id, slug: "berlin"})
    {:ok, %{country: country, federal_state: federal_state}}
  end
end
