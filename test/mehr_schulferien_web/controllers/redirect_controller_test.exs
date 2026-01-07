defmodule MehrSchulferienWeb.RedirectControllerTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  describe "cities redirects" do
    setup do
      # Create test data hierarchy
      country = get_or_create_deutschland()

      federal_state =
        insert(:federal_state, %{parent_location_id: country.id, name: "Nordrhein-Westfalen"})

      county = insert(:county, %{parent_location_id: federal_state.id, name: "Bielefeld"})

      city =
        insert(:city, %{
          parent_location_id: county.id,
          name: "Bielefeld",
          slug: "bielefeld"
        })

      # Create zip code and mapping
      zip_code = insert(:zip_code, %{value: "33619"})

      insert(:zip_code_mapping, %{
        location_id: city.id,
        zip_code_id: zip_code.id
      })

      {:ok, %{city: city, country: country}}
    end

    test "redirects /cities/:city_slug to /ferien/deutschland/stadt/:city_slug with 301", %{
      conn: conn,
      city: city,
      country: country
    } do
      # This redirects from zip-code-based URL to proper city slug
      conn = get(conn, "/cities/33619-bielefeld")
      assert conn.status == 301
      assert redirected_to(conn, 301) == "/ferien/#{country.slug}/stadt/#{city.slug}"
    end

    test "redirects /cities/:city_slug/:year to /ferien/deutschland/stadt/:city_slug/:year with 301",
         %{conn: conn, city: city, country: country} do
      # This redirects from zip-code-based URL to proper city slug with year
      conn = get(conn, "/cities/33619-bielefeld/2025")
      assert conn.status == 301
      # The redirect controller redirects to the URL with year
      assert redirected_to(conn, 301) == "/ferien/#{country.slug}/stadt/#{city.slug}/2025"
    end
  end

  describe "land redirects" do
    test "redirects /land/:country_slug/stadt/:city_slug to /ferien/:country_slug/stadt/:city_slug",
         %{conn: conn} do
      conn = get(conn, "/land/deutschland/stadt/33619-bielefeld")
      assert redirected_to(conn, 301) == "/ferien/deutschland/stadt/33619-bielefeld"
    end

    test "redirects /land/:country_slug/stadt/:city_slug/:year to /ferien/:country_slug/stadt/:city_slug/:year",
         %{conn: conn} do
      conn = get(conn, "/land/deutschland/stadt/33619-bielefeld/2025")
      assert redirected_to(conn, 301) == "/ferien/deutschland/stadt/33619-bielefeld/2025"
    end
  end

  describe "legacy /schools/ redirects" do
    test "redirects /schools/:slug/:year to /ferien/d/schule/:slug", %{conn: conn} do
      conn = get(conn, "/schools/86978-volksschule-hohenfurch/2026")
      assert redirected_to(conn, 301) == "/ferien/d/schule/86978-volksschule-hohenfurch"
    end

    test "redirects /schools/:slug to /ferien/d/schule/:slug", %{conn: conn} do
      conn = get(conn, "/schools/86978-volksschule-hohenfurch")
      assert redirected_to(conn, 301) == "/ferien/d/schule/86978-volksschule-hohenfurch"
    end

    test "redirects /schools/:slug with query params to /ferien/d/schule/:slug", %{conn: conn} do
      conn = get(conn, "/schools/07545-zabel-gymnasium?additional_categories=juedischer-feiertag")
      assert redirected_to(conn, 301) == "/ferien/d/schule/07545-zabel-gymnasium"
    end
  end
end
