defmodule MehrSchulferienWeb.FederalStateControllerTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.TestHelpers

  setup %{conn: conn} do
    country = get_or_create_deutschland()
    federal_state = insert(:federal_state, %{slug: "bayern", parent_location_id: country.id})

    {:ok, %{conn: conn, country: country, federal_state: federal_state}}
  end

  test "GET /land/:country_slug/bundesland/:federal_state_slug redirects to /ferien/ path",
       %{
         conn: conn,
         country: country,
         federal_state: federal_state
       } do
    conn = get(conn, "/land/#{country.slug}/bundesland/#{federal_state.slug}")

    # Get the current year
    _current_year = MehrSchulferien.Calendars.DateHelpers.today_berlin().year

    # Assert that the request is redirected (301 status code)
    assert redirected_to(conn, 301) =~
             "/ferien/#{country.slug}/bundesland/#{federal_state.slug}"
  end

  test "GET /ferien/:country_slug/bundesland/:federal_state_slug/:year returns 404 when no periods exist for the year",
       %{
         conn: conn,
         country: country,
         federal_state: federal_state
       } do
    # Use a year far in the future (2050) to ensure no periods exist
    year_without_data = 2050

    # Make the request to the show_year action for a year with no periods
    conn =
      get(conn, "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/#{year_without_data}")

    # Assert that the response has a 404 status code directly
    assert conn.status == 404

    # Assert that the page still renders with the correct layout and content
    assert html_response(conn, 404) =~ federal_state.name
    assert html_response(conn, 404) =~ "#{year_without_data}"
  end

  describe "past year pages" do
    # The year gate never reads the real clock: each request pins "today"
    # via the ?today= override provided by DateAssignsPlug.
    test "a past year 301-redirects to the evergreen state page", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn =
        get(
          conn,
          "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/2021?today=15.06.2026"
        )

      assert redirected_to(conn, 301) ==
               "/ferien/#{country.slug}/bundesland/#{federal_state.slug}"
    end

    test "the current year renders instead of redirecting", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn =
        get(
          conn,
          "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/2026?today=15.06.2026"
        )

      # No period data is inserted here, so the page renders with a 404
      # status - the important part is that it does NOT redirect.
      assert conn.status == 404
      assert html_response(conn, 404) =~ federal_state.name
    end

    test "a year starts redirecting once it lies in the past", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn =
        get(
          conn,
          "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/2026?today=15.06.2027"
        )

      assert redirected_to(conn, 301) ==
               "/ferien/#{country.slug}/bundesland/#{federal_state.slug}"
    end
  end

  describe "evergreen federal state page (year-less URL)" do
    setup %{country: country, federal_state: federal_state} do
      today = Date.utc_today()

      summer_type =
        insert(:holiday_or_vacation_type,
          name: "Sommer",
          default_is_school_vacation: true,
          country_location_id: country.id
        )

      insert(:period,
        location_id: federal_state.id,
        holiday_or_vacation_type_id: summer_type.id,
        starts_on: today,
        ends_on: Date.add(today, 14),
        is_school_vacation: true,
        is_valid_for_students: true
      )

      winter_type =
        insert(:holiday_or_vacation_type,
          name: "Winter",
          default_is_school_vacation: true,
          country_location_id: country.id
        )

      insert(:period,
        location_id: federal_state.id,
        holiday_or_vacation_type_id: winter_type.id,
        starts_on: Date.new!(today.year + 1, 2, 1),
        ends_on: Date.new!(today.year + 1, 2, 10),
        is_school_vacation: true,
        is_valid_for_students: true
      )

      holiday_type =
        insert(:holiday_or_vacation_type,
          name: "Neujahr",
          default_is_public_holiday: true,
          default_is_school_vacation: false,
          country_location_id: country.id
        )

      insert(:period,
        location_id: federal_state.id,
        holiday_or_vacation_type_id: holiday_type.id,
        starts_on: Date.add(today, 30),
        ends_on: Date.add(today, 30),
        is_public_holiday: true,
        is_valid_for_everybody: true
      )

      {:ok, current_year: today.year, next_year: today.year + 1}
    end

    test "renders a real page with head-term H1 and both years of data", %{
      conn: conn,
      country: country,
      federal_state: federal_state,
      current_year: current_year,
      next_year: next_year
    } do
      conn = get(conn, "/ferien/#{country.slug}/bundesland/#{federal_state.slug}")
      html = html_response(conn, 200)

      assert html =~ "Schulferien #{federal_state.name}"
      assert html =~ "#{current_year}"
      assert html =~ "#{next_year}"
    end

    test "has a self-referencing canonical to the year-less URL", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn = get(conn, "/ferien/#{country.slug}/bundesland/#{federal_state.slug}")
      html = html_response(conn, 200)

      assert html =~ ~s(rel="canonical")
      assert html =~ "/ferien/#{country.slug}/bundesland/#{federal_state.slug}\""
    end

    test "links to the year pages for year-specific queries", %{
      conn: conn,
      country: country,
      federal_state: federal_state,
      current_year: current_year
    } do
      conn = get(conn, "/ferien/#{country.slug}/bundesland/#{federal_state.slug}")

      assert html_response(conn, 200) =~
               "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/#{current_year}"
    end

    test "returns 404 when the state has no vacation data", %{
      conn: conn,
      country: country
    } do
      empty_state =
        insert(:federal_state, %{slug: "saarland", parent_location_id: country.id})

      conn = get(conn, "/ferien/#{country.slug}/bundesland/#{empty_state.slug}")

      assert conn.status == 404
    end
  end

  describe "SEO meta tags on the year page" do
    setup %{country: country, federal_state: federal_state} do
      vacation_type =
        insert(:holiday_or_vacation_type,
          name: "Sommer",
          default_is_school_vacation: true,
          country_location_id: country.id
        )

      insert(:period,
        location_id: federal_state.id,
        holiday_or_vacation_type_id: vacation_type.id,
        starts_on: Date.utc_today(),
        ends_on: Date.add(Date.utc_today(), 14),
        is_school_vacation: true,
        is_valid_for_students: true
      )

      holiday_type =
        insert(:holiday_or_vacation_type,
          name: "Neujahr",
          default_is_public_holiday: true,
          default_is_school_vacation: false,
          country_location_id: country.id
        )

      insert(:period,
        location_id: federal_state.id,
        holiday_or_vacation_type_id: holiday_type.id,
        starts_on: Date.add(Date.utc_today(), 30),
        ends_on: Date.add(Date.utc_today(), 30),
        is_public_holiday: true,
        is_valid_for_everybody: true
      )

      {:ok, year: Date.utc_today().year}
    end

    test "renders a self-referencing canonical link", %{
      conn: conn,
      country: country,
      federal_state: federal_state,
      year: year
    } do
      conn = get(conn, "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/#{year}")

      assert html_response(conn, 200) =~
               ~s(rel="canonical")

      assert html_response(conn, 200) =~
               "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/#{year}\""
    end

    test "renders og:image and large Twitter card pointing to the handwritten image", %{
      conn: conn,
      country: country,
      federal_state: federal_state,
      year: year
    } do
      conn = get(conn, "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/#{year}")
      html = html_response(conn, 200)

      assert html =~ ~s(property="og:image")

      assert html =~
               "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/#{year}/handwritten.webp"

      assert html =~ ~s(property="twitter:card" content="summary_large_image")
    end

    test "does not include the dead Universal Analytics snippet", %{
      conn: conn,
      country: country,
      federal_state: federal_state,
      year: year
    } do
      conn = get(conn, "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/#{year}")
      html = html_response(conn, 200)

      refute html =~ "google-analytics.com"
      refute html =~ "UA-774512"
    end
  end

  test "GET landkreise-und-staedte sets a page-specific title", %{
    conn: conn,
    country: country,
    federal_state: federal_state
  } do
    conn =
      get(conn, "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/landkreise-und-staedte")

    response = html_response(conn, 200)

    assert response =~ "Landkreise und Städte in #{federal_state.name}"
    refute response =~ "<title>\n  Schulferien, Feiertage, Brückentage und bewegliche Ferientage"
  end
end
