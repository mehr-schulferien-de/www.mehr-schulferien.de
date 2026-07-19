defmodule MehrSchulferienWeb.SitemapSystemTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest

  describe "sitemap.xml" do
    test "is a sitemap index pointing to the per-type child sitemaps", %{conn: conn} do
      conn = get(conn, "/sitemap.xml")

      assert conn.status == 200
      assert response_content_type(conn, :xml)

      response = response(conn, 200)
      assert response =~ ~s(<?xml version="1.0" encoding="UTF-8"?>)
      assert response =~ ~s(<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">)

      for child <- ~w(static bundeslaender staedte schulen) do
        assert response =~ "https://www.mehr-schulferien.de/sitemap-#{child}.xml"
      end
    end
  end

  describe "sitemap-static.xml" do
    test "contains the static pages", %{conn: conn} do
      conn = get(conn, "/sitemap-static.xml")

      assert conn.status == 200
      assert response_content_type(conn, :xml)

      response = response(conn, 200)
      assert response =~ ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">)

      # Homepage
      assert response =~ ~r{<loc>https?://[^<]+/</loc>}

      # Developers page
      assert response =~ ~r{<loc>https?://[^<]+/developers</loc>}

      # Vacation type overview pages
      for slug <-
            ~w(sommerferien osterferien herbstferien weihnachtsferien winterferien pfingstferien) do
        assert response =~ ~r{<loc>https?://[^<]+/#{slug}</loc>}
      end
    end
  end
end
