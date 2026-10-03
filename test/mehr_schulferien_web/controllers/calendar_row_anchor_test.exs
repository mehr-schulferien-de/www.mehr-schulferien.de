defmodule MehrSchulferienWeb.CalendarRowAnchorTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.Calendars.DateHelpers

  # A row of the Ferientermine table jumps to its month in the Kalenderansicht.
  # The link and the month id are built in different components, so every page
  # that renders the table is checked for anchors without a target.
  @today "03.10.2026"

  setup do
    MehrSchulferien.Cache.clear_query_cache()

    country = insert(:country, slug: "d", name: "Deutschland")

    federal_state =
      insert(:federal_state, parent_location_id: country.id, slug: "rheinland-pfalz")

    county = insert(:county, parent_location_id: federal_state.id)
    city = insert(:city, parent_location_id: county.id)
    school = insert(:school, parent_location_id: city.id)

    herbst = vacation_type(country, "herbst", "Herbst", "Herbstferien")
    weihnachten = vacation_type(country, "weihnachten", "Weihnachten", "Weihnachtsferien")
    ostern = vacation_type(country, "ostern", "Ostern", "Osterferien")
    sommer = vacation_type(country, "sommer", "Sommer", "Sommerferien")

    vacation(federal_state, weihnachten, ~D[2025-12-22], ~D[2026-01-07])
    vacation(federal_state, ostern, ~D[2026-03-30], ~D[2026-04-10])
    # Started last month and still running on @today
    vacation(federal_state, herbst, ~D[2026-09-28], ~D[2026-10-09])
    vacation(federal_state, weihnachten, ~D[2026-12-23], ~D[2027-01-08])
    vacation(federal_state, ostern, ~D[2027-03-22], ~D[2027-04-02])
    vacation(federal_state, sommer, ~D[2027-06-28], ~D[2027-08-06])

    {:ok, country: country, federal_state: federal_state, city: city, school: school}
  end

  test "school page: every row lands on a rendered month", %{conn: conn, school: school} do
    html = page(conn, ~p"/ferien/d/schule/#{school.slug}")

    anchors = assert_anchors_resolve(html)

    assert "#maerz2027" in anchors
    # The running Herbstferien began in September, which is no longer rendered
    assert "#oktober2026" in anchors
  end

  test "city page: every row lands on a rendered month", %{conn: conn, city: city} do
    html = page(conn, ~p"/ferien/d/stadt/#{city.slug}")

    anchors = assert_anchors_resolve(html)

    assert "#maerz2026" in anchors
    # Weihnachtsferien 2025 began before the first rendered month
    assert "#januar2026" in anchors
  end

  test "federal state year page: every row lands on a rendered month", %{conn: conn} do
    html = page(conn, ~p"/ferien/d/bundesland/rheinland-pfalz/2027")

    assert "#maerz2027" in assert_anchors_resolve(html)
  end

  test "federal state overview has no calendar, so its rows are not clickable", %{conn: conn} do
    html = page(conn, ~p"/ferien/d/bundesland/rheinland-pfalz")

    assert html =~ "Osterferien"
    assert row_anchors(html) == []
  end

  test "season page: only rows with a rendered month are clickable", %{conn: conn} do
    html = page(conn, "/osterferien/rheinland-pfalz/2027")

    assert assert_anchors_resolve(html) == ["#maerz2027"]
  end

  test "season page across New Year renders January of the following year", %{conn: conn} do
    html = page(conn, "/weihnachtsferien/rheinland-pfalz/2026")

    assert html =~ ~s(id="dezember2026")
    assert html =~ ~s(id="januar2027")
    refute html =~ ~s(id="januar2026")
    assert_anchors_resolve(html)
  end

  test "country page: the dates link to the month on the state's year page", %{
    conn: conn,
    country: country,
    federal_state: federal_state
  } do
    # The country page reads the real clock, so its period lives in the running year
    year = DateHelpers.today_berlin().year
    fruehjahr = vacation_type(country, "fruehjahr", "Frühjahr", "Frühjahrsferien")
    vacation(federal_state, fruehjahr, Date.new!(year, 3, 2), Date.new!(year, 3, 6))

    target = "/ferien/d/bundesland/rheinland-pfalz/#{year}#maerz#{year}"

    assert conn
           |> get(~p"/ferien/d")
           |> html_response(200)
           |> Floki.parse_document!()
           |> Floki.attribute("a[href*='#']", "href")
           |> Enum.member?(target)

    year_page =
      conn |> get(~p"/ferien/d/bundesland/rheinland-pfalz/#{year}") |> html_response(200)

    assert year_page =~ ~s(id="maerz#{year}")
  end

  defp page(conn, path) do
    conn |> get(path, today: @today) |> html_response(200)
  end

  defp row_anchors(html) do
    html
    |> Floki.parse_document!()
    |> Floki.attribute("tr[onclick]", "onclick")
    |> Enum.map(fn onclick ->
      [_, anchor] = Regex.run(~r/window\.location\.href='(#[^']+)'/, onclick)
      anchor
    end)
  end

  defp assert_anchors_resolve(html) do
    doc = Floki.parse_document!(html)
    anchors = row_anchors(html)

    assert anchors != []

    for "#" <> id <- anchors do
      assert Floki.find(doc, "section[id='#{id}']") != [], "no calendar month with id #{id}"
    end

    anchors
  end

  defp vacation_type(country, slug, name, colloquial) do
    insert(:holiday_or_vacation_type,
      slug: slug,
      name: name,
      colloquial: colloquial,
      default_is_school_vacation: true,
      country_location_id: country.id
    )
  end

  defp vacation(location, type, starts_on, ends_on) do
    insert(:period,
      location_id: location.id,
      holiday_or_vacation_type_id: type.id,
      starts_on: starts_on,
      ends_on: ends_on,
      is_school_vacation: true,
      is_valid_for_students: true,
      is_valid_for_everybody: false,
      is_public_holiday: false
    )
  end
end
