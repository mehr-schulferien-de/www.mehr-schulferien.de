defmodule MehrSchulferienWeb.SeoLandingPagesTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory

  setup do
    country = insert(:country, slug: "d", name: "Deutschland")

    state =
      insert(:federal_state,
        parent_location_id: country.id,
        slug: "nordrhein-westfalen",
        name: "Nordrhein-Westfalen"
      )

    county = insert(:county, parent_location_id: state.id)
    city = insert(:city, parent_location_id: county.id, slug: "bonn", name: "Bonn")

    type =
      insert(:holiday_or_vacation_type,
        country_location_id: country.id,
        name: "Herbst",
        colloquial: "Herbstferien",
        slug: "herbst",
        default_is_school_vacation: true
      )

    for {first, last} <- [{~D[2026-10-17], ~D[2026-10-31]}, {~D[2027-10-23], ~D[2027-11-06]}] do
      insert(:period,
        location_id: state.id,
        holiday_or_vacation_type_id: type.id,
        starts_on: first,
        ends_on: last,
        is_school_vacation: true,
        is_valid_for_students: true
      )
    end

    {:ok, city: city}
  end

  test "state overview answers next vacation before its table and cites official guidance", %{
    conn: conn
  } do
    html =
      conn
      |> get("/ferien/d/bundesland/nordrhein-westfalen?today=19.09.2026")
      |> html_response(200)

    doc = Floki.parse_document!(html)
    assert Floki.find(doc, "title") |> Floki.text() =~ "Schulferien NRW 2026"
    assert Floki.find(doc, "#naechste-ferien") |> Floki.text() =~ "17.10.2026"

    assert Floki.find(doc, "#naechste-ferien a") |> Floki.attribute("href") == [
             "/herbstferien/nordrhein-westfalen/2026"
           ]

    assert html =~ "https://bass.schule.nrw/191.htm"
    assert html =~ "Schulkonferenz"
    assert html =~ "/ferien-widget?bundesland=nordrhein-westfalen"
  end

  test "season pages link national year and evergreen state with valid country breadcrumbs", %{
    conn: conn
  } do
    for path <- ["/herbstferien/nordrhein-westfalen/2026", "/herbstferien/nordrhein-westfalen"] do
      html = conn |> recycle() |> get(path <> "?today=19.09.2026") |> html_response(200)
      doc = Floki.parse_document!(html)

      assert Floki.find(doc, "a[href='/herbstferien/2026']") |> Floki.text() =~
               "allen Bundesländern"

      assert Floki.find(doc, "a[href='/ferien/d/bundesland/nordrhein-westfalen']") |> Floki.text() =~
               "Alle Schulferien"

      refute html =~ "/ferien/deutschland"
    end
  end

  test "season snippet includes actual dates and NRW without changing canonical URL", %{
    conn: conn
  } do
    doc =
      conn
      |> get("/herbstferien/nordrhein-westfalen/2026?today=19.09.2026")
      |> html_response(200)
      |> Floki.parse_document!()

    title = doc |> Floki.find("title") |> Floki.text()
    assert title =~ "Herbstferien NRW 2026"
    assert title =~ "17.10."

    assert Floki.find(doc, "link[rel='canonical']") |> Floki.attribute("href") == [
             "https://www.mehr-schulferien.de/herbstferien/nordrhein-westfalen/2026"
           ]
  end

  test "city explains statewide dates and offers contextual state link", %{conn: conn, city: city} do
    html = conn |> get("/ferien/d/stadt/#{city.slug}?today=19.09.2026") |> html_response(200)
    text = html |> Floki.parse_document!() |> Floki.text() |> String.replace(~r/\s+/, " ")
    assert text =~ "Für Bonn gelten die landesweiten Ferientermine"
    assert html =~ "Alle Schulferien in Nordrhein-Westfalen"
    assert html =~ "23.10.27"
    doc = Floki.parse_document!(html)

    assert Floki.find(doc, "link[rel='canonical']") |> Floki.attribute("href") == [
             "http://localhost:4002/ferien/d/stadt/bonn"
           ]

    assert Floki.find(doc, "#schulbeginn") |> Floki.text() =~ "02.11.2026"
    assert html =~ "#naechste-ferien" or html =~ ~s(id="naechste-ferien")
  end

  test "homepage provides year-specific national season links", %{conn: conn} do
    html = conn |> get("/") |> html_response(200)
    year = MehrSchulferien.Calendars.DateHelpers.today_berlin().year

    for season <- ["herbstferien", "weihnachtsferien", "osterferien"] do
      assert html =~ ~s(href="/#{season}/#{year}")
    end
  end
end
