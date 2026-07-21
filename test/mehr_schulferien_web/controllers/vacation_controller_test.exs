defmodule MehrSchulferienWeb.VacationControllerTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory

  # All date-dependent behavior goes through the ?today= override (the
  # injectable clock), pinned to mid-year so season logic is deterministic.
  @year Date.utc_today().year
  @today "01.07.#{@year}"

  defp create_base_data do
    country = insert(:country, slug: "d", name: "Deutschland")

    federal_state =
      insert(:federal_state,
        parent_location_id: country.id,
        slug: "niedersachsen",
        name: "Niedersachsen"
      )

    # Production database slug is "ostern" (URL slug: "osterferien")
    vacation_type =
      insert(:holiday_or_vacation_type,
        slug: "ostern",
        name: "Ostern",
        colloquial: "Osterferien",
        default_is_school_vacation: true,
        country_location_id: country.id
      )

    %{country: country, federal_state: federal_state, vacation_type: vacation_type}
  end

  defp insert_easter_period(federal_state, vacation_type, year) do
    insert(:period,
      location_id: federal_state.id,
      holiday_or_vacation_type_id: vacation_type.id,
      starts_on: Date.new!(year, 3, 25),
      ends_on: Date.new!(year, 4, 5),
      is_school_vacation: true,
      is_valid_for_students: true,
      is_valid_for_everybody: false,
      is_public_holiday: false
    )
  end

  describe "show/2 with canonical slug" do
    setup do
      {:ok, create_base_data()}
    end

    test "returns 404 when vacation period does not exist for the year", %{
      conn: conn,
      federal_state: federal_state,
      vacation_type: vacation_type
    } do
      insert_easter_period(federal_state, vacation_type, @year)

      # Future year without data still renders (as 404) instead of redirecting
      conn = get(conn, "/osterferien/niedersachsen/#{@year + 2}?today=#{@today}")

      assert html_response(conn, 404) =~ "werden in der Regel"
    end

    test "returns 200 when vacation period exists for the year", %{
      conn: conn,
      federal_state: federal_state,
      vacation_type: vacation_type
    } do
      insert_easter_period(federal_state, vacation_type, @year)

      conn = get(conn, "/osterferien/niedersachsen/#{@year}?today=#{@today}")

      response = html_response(conn, 200)
      assert response =~ "25.03.-05.04.#{@year}"
    end

    test "redirects when vacation type doesn't exist at all", %{conn: conn} do
      conn = get(conn, "/fantasieferien/niedersachsen/#{@year}?today=#{@today}")

      assert redirected_to(conn) == "/ferien/d/bundesland/niedersachsen/#{@year}"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Diese Ferienart existiert nicht"
    end

    test "redirects when vacation type exists but not for this state", %{
      conn: conn,
      country: country
    } do
      insert(:holiday_or_vacation_type,
        slug: "herbst",
        name: "Herbstferien",
        colloquial: "Herbstferien",
        default_is_school_vacation: true,
        country_location_id: country.id
      )

      conn = get(conn, "/herbstferien/niedersachsen/#{@year}?today=#{@today}")

      assert redirected_to(conn) == "/ferien/d/bundesland/niedersachsen/#{@year}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "gibt es in Niedersachsen nicht"
    end

    test "past years 301 to the evergreen season page", %{
      conn: conn,
      federal_state: federal_state,
      vacation_type: vacation_type
    } do
      insert_easter_period(federal_state, vacation_type, @year - 1)

      conn = get(conn, "/osterferien/niedersachsen/#{@year - 1}?today=#{@today}")

      assert redirected_to(conn, 301) == "/osterferien/niedersachsen"
    end

    test "non-year third segment is a 404 (router constraints are not enforced)", %{conn: conn} do
      conn = get(conn, "/osterferien/niedersachsen/kalender")
      assert conn.status == 404
    end
  end

  describe "show/2 with legacy slug" do
    setup do
      {:ok, create_base_data()}
    end

    test "301s osternferien to osterferien keeping state and year", %{
      conn: conn,
      federal_state: federal_state,
      vacation_type: vacation_type
    } do
      insert_easter_period(federal_state, vacation_type, @year)

      conn = get(conn, "/osternferien/niedersachsen/#{@year}")

      assert redirected_to(conn, 301) == "/osterferien/niedersachsen/#{@year}"
    end

    test "301s weihnachtenferien to weihnachtsferien", %{conn: conn} do
      conn = get(conn, "/weihnachtenferien/niedersachsen/#{@year}")

      assert redirected_to(conn, 301) == "/weihnachtsferien/niedersachsen/#{@year}"
    end

    test "301s year-less legacy slug to canonical evergreen URL", %{conn: conn} do
      conn = get(conn, "/osternferien/niedersachsen")

      assert redirected_to(conn, 301) == "/osterferien/niedersachsen"
    end
  end

  describe "evergreen season page (year-less URL)" do
    setup do
      {:ok, create_base_data()}
    end

    test "renders a real page with current and next year dates", %{
      conn: conn,
      federal_state: federal_state,
      vacation_type: vacation_type
    } do
      insert_easter_period(federal_state, vacation_type, @year)
      insert_easter_period(federal_state, vacation_type, @year + 1)

      conn = get(conn, "/osterferien/niedersachsen?today=#{@today}")

      response = html_response(conn, 200)
      assert response =~ "Osterferien Niedersachsen"
      assert response =~ "#{@year}"
      assert response =~ "#{@year + 1}"
      # Self-canonical: the year-less URL is the canonical URL
      assert response =~
               ~s(rel="canonical" href="https://www.mehr-schulferien.de/osterferien/niedersachsen")
    end

    test "renders FAQPage structured data", %{
      conn: conn,
      federal_state: federal_state,
      vacation_type: vacation_type
    } do
      insert_easter_period(federal_state, vacation_type, @year)

      conn = get(conn, "/osterferien/niedersachsen?today=#{@today}")

      response = html_response(conn, 200)
      assert response =~ "FAQPage"
      assert response =~ "Wann sind Osterferien"
    end

    test "404s when the state has no periods of this type in the window", %{
      conn: conn,
      federal_state: federal_state,
      vacation_type: vacation_type
    } do
      # Type exists for the state, but only with a long-past period
      insert_easter_period(federal_state, vacation_type, @year - 3)

      conn = get(conn, "/osterferien/niedersachsen?today=#{@today}")

      assert html_response(conn, 404)
    end

    test "redirects to state page when the type does not exist for the state", %{
      conn: conn,
      country: country
    } do
      insert(:holiday_or_vacation_type,
        slug: "winter",
        name: "Winter",
        colloquial: "Winterferien",
        default_is_school_vacation: true,
        country_location_id: country.id
      )

      conn = get(conn, "/winterferien/niedersachsen?today=#{@today}")

      assert redirected_to(conn) == "/ferien/d/bundesland/niedersachsen"
    end
  end

  describe "national season year page" do
    setup do
      {:ok, create_base_data()}
    end

    test "renders all states for the season and year", %{
      conn: conn,
      country: country,
      federal_state: federal_state,
      vacation_type: vacation_type
    } do
      bayern =
        insert(:federal_state, parent_location_id: country.id, slug: "bayern", name: "Bayern")

      insert_easter_period(federal_state, vacation_type, @year)

      insert(:period,
        location_id: bayern.id,
        holiday_or_vacation_type_id: vacation_type.id,
        starts_on: Date.new!(@year, 3, 30),
        ends_on: Date.new!(@year, 4, 10),
        is_school_vacation: true,
        is_valid_for_students: true
      )

      conn = get(conn, "/osterferien/#{@year}?today=#{@today}")

      response = html_response(conn, 200)
      assert response =~ "Osterferien #{@year}"
      assert response =~ "Niedersachsen"
      assert response =~ "Bayern"

      assert response =~
               ~s(rel="canonical" href="https://www.mehr-schulferien.de/osterferien/#{@year}")
    end

    test "past year 301s to the national season overview", %{conn: conn} do
      conn = get(conn, "/osterferien/#{@year - 1}?today=#{@today}")

      assert redirected_to(conn, 301) == "/osterferien"
    end

    test "season without a national config 404s", %{conn: conn} do
      conn = get(conn, "/fruehjahrsferien/#{@year}?today=#{@today}")
      assert conn.status == 404
    end
  end
end
