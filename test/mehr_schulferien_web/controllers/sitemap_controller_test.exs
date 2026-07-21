defmodule MehrSchulferienWeb.SitemapControllerTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.TestHelpers

  setup %{conn: conn} do
    # The sitemaps are built from Locations.list_countries/0, which caches
    # into the location hierarchy cache. Stale country ids from other tests
    # would make the federal state lookups come up empty.
    MehrSchulferien.Cache.clear_all_location_hierarchies()
    MehrSchulferien.Cache.clear_query_cache()
    {:ok, %{conn: conn}}
  end

  describe "GET /sitemap.xml (sitemap index)" do
    test "lists the per-type child sitemaps", %{conn: conn} do
      conn = get(conn, "/sitemap.xml")

      assert response_content_type(conn, :xml)
      response = response(conn, 200)

      assert response =~ "<sitemapindex"

      for child <- ~w(static bundeslaender staedte schulen) do
        assert response =~
                 "<loc>https://www.mehr-schulferien.de/sitemap-#{child}.xml</loc>"
      end
    end
  end

  describe "child sitemaps" do
    setup [:add_locations_with_periods]

    test "static: contains homepage, vacation overviews and country page", %{
      conn: conn,
      country: country
    } do
      response = response(get(conn, "/sitemap-static.xml"), 200)

      assert response =~ "<loc>https://www.mehr-schulferien.de/</loc>"
      assert response =~ "<loc>https://www.mehr-schulferien.de/sommerferien</loc>"
      assert response =~ "<loc>https://www.mehr-schulferien.de/ferien/#{country.slug}</loc>"
      assert response =~ "<loc>https://www.mehr-schulferien.de/briefe</loc>"
      assert response =~ "<loc>https://www.mehr-schulferien.de/impressum</loc>"
    end

    test "static: contains the national bridge day overview pages", %{
      conn: conn,
      country: country
    } do
      current_year = Date.utc_today().year
      response = response(get(conn, "/sitemap-static.xml"), 200)

      for year <- [current_year, current_year + 1] do
        assert response =~
                 "<loc>https://www.mehr-schulferien.de/brueckentage/#{country.slug}/#{year}</loc>"
      end
    end

    test "static: contains the national season year pages and Feiertage pages", %{
      conn: conn,
      country: country
    } do
      current_year = Date.utc_today().year
      response = response(get(conn, "/sitemap-static.xml"), 200)

      for year <- [current_year, current_year + 1] do
        assert response =~ "<loc>https://www.mehr-schulferien.de/sommerferien/#{year}</loc>"

        assert response =~
                 "<loc>https://www.mehr-schulferien.de/feiertage/#{country.slug}/#{year}</loc>"
      end

      assert response =~ "<loc>https://www.mehr-schulferien.de/feiertage/#{country.slug}</loc>"
    end

    test "bundeslaender: contains evergreen season, bridge day and Feiertage URLs", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      current_year = Date.utc_today().year
      response = response(get(conn, "/sitemap-bundeslaender.xml"), 200)

      # Season URLs use the canonical German compound slug (osterferien,
      # not the generated "osternferien").
      assert response =~
               "<loc>https://www.mehr-schulferien.de/osterferien/#{federal_state.slug}</loc>"

      assert response =~
               "<loc>https://www.mehr-schulferien.de/osterferien/#{federal_state.slug}/#{current_year}</loc>"

      refute response =~ "osternferien"

      assert response =~
               "<loc>https://www.mehr-schulferien.de/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}</loc>"

      assert response =~
               "<loc>https://www.mehr-schulferien.de/feiertage/#{country.slug}/bundesland/#{federal_state.slug}</loc>"

      assert response =~
               "<loc>https://www.mehr-schulferien.de/feiertage/#{country.slug}/bundesland/#{federal_state.slug}/#{current_year}</loc>"
    end

    test "bundeslaender: contains the evergreen year-less federal state URL", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      response = response(get(conn, "/sitemap-bundeslaender.xml"), 200)

      assert response =~
               "<loc>https://www.mehr-schulferien.de/ferien/#{country.slug}/bundesland/#{federal_state.slug}</loc>"
    end

    test "bundeslaender: contains year, bridge day and date query URLs", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      current_year = Date.utc_today().year
      response = response(get(conn, "/sitemap-bundeslaender.xml"), 200)

      assert response =~
               "<loc>https://www.mehr-schulferien.de/ferien/#{country.slug}/bundesland/#{federal_state.slug}/#{current_year}</loc>"

      assert response =~
               "<loc>https://www.mehr-schulferien.de/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/#{current_year}</loc>"

      assert response =~
               "<loc>https://www.mehr-schulferien.de/ist-heute-schulfrei/#{federal_state.slug}</loc>"
    end

    test "bundeslaender: does not contain noindexed thin pages (urlaubsplaner)", %{conn: conn} do
      # Urlaubsplaner pages carry a noindex meta tag; listing them in the
      # sitemap would send crawlers to pages they are told not to index.
      refute response(get(conn, "/sitemap-bundeslaender.xml"), 200) =~ "urlaubsplaner"
    end

    test "staedte: contains all cities, including those without schools", %{
      conn: conn,
      country: country,
      city: city,
      city_without_school: city_without_school
    } do
      response = response(get(conn, "/sitemap-staedte.xml"), 200)

      assert response =~
               "<loc>https://www.mehr-schulferien.de/ferien/#{country.slug}/stadt/#{city.slug}</loc>"

      assert response =~
               "<loc>https://www.mehr-schulferien.de/ferien/#{country.slug}/stadt/#{city_without_school.slug}</loc>"
    end

    test "schulen: lists school ferien pages but not the noindexed briefe pages", %{
      conn: conn,
      country: country,
      school: school
    } do
      response = response(get(conn, "/sitemap-schulen.xml"), 200)

      assert response =~
               "<loc>https://www.mehr-schulferien.de/ferien/#{country.slug}/schule/#{school.slug}</loc>"

      refute response =~ "briefe"
    end

    test "schulen: leaves out quarantined schools", %{
      conn: conn,
      quarantined_school: quarantined_school
    } do
      refute response(get(conn, "/sitemap-schulen.xml"), 200) =~ quarantined_school.slug
    end
  end

  defp add_locations_with_periods(_) do
    country = get_or_create_deutschland()
    federal_state = insert(:federal_state, %{parent_location_id: country.id, slug: "berlin"})

    holiday_type =
      insert(:holiday_or_vacation_type, %{
        name: "Test Holiday",
        country_location_id: country.id
      })

    current_year = Date.utc_today().year

    # Public holidays for the current and next year so both year pages
    # qualify for the bundeslaender sitemap.
    for year <- [current_year, current_year + 1] do
      insert(:public_holiday, %{
        is_valid_for_everybody: true,
        location_id: federal_state.id,
        holiday_or_vacation_type_id: holiday_type.id,
        starts_on: Date.new!(year, 5, 1),
        ends_on: Date.new!(year, 5, 1),
        display_priority: 1
      })
    end

    # A school vacation type with periods in both years so the season
    # URLs (evergreen and per year) appear in the bundeslaender sitemap.
    easter_type =
      insert(:holiday_or_vacation_type, %{
        name: "Ostern",
        slug: "ostern",
        colloquial: "Osterferien",
        default_is_school_vacation: true,
        country_location_id: country.id
      })

    for year <- [current_year, current_year + 1] do
      insert(:period, %{
        location_id: federal_state.id,
        holiday_or_vacation_type_id: easter_type.id,
        starts_on: Date.new!(year, 3, 25),
        ends_on: Date.new!(year, 4, 5),
        is_school_vacation: true,
        is_valid_for_students: true
      })
    end

    county = insert(:county, %{parent_location_id: federal_state.id})
    city = insert(:city, %{parent_location_id: county.id})
    city_without_school = insert(:city, %{parent_location_id: county.id})
    school = insert(:school, %{parent_location_id: city.id})
    quarantined_school = insert(:school, %{parent_location_id: city.id, is_quarantined: true})

    {:ok,
     %{
       country: country,
       federal_state: federal_state,
       city: city,
       city_without_school: city_without_school,
       school: school,
       quarantined_school: quarantined_school
     }}
  end
end
