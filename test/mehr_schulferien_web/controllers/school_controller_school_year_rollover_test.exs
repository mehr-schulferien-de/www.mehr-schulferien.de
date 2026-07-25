defmodule MehrSchulferienWeb.SchoolControllerSchoolYearRolloverTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory

  # The nominal school year runs until 31 July, so between the start of the
  # Sommerferien and 1 August the school page used to lead with dates that
  # were long over and advertise the finished school year in its title.
  setup do
    MehrSchulferien.Cache.clear_query_cache()

    country = insert(:country, slug: "deutschland")
    federal_state = insert(:federal_state, parent_location_id: country.id)
    county = insert(:county, parent_location_id: federal_state.id)
    city = insert(:city, parent_location_id: county.id)
    school = insert(:school, parent_location_id: city.id)

    herbst = insert(:holiday_or_vacation_type, name: "Herbst", country_location_id: country.id)
    oster = insert(:holiday_or_vacation_type, name: "Oster", country_location_id: country.id)
    sommer = insert(:holiday_or_vacation_type, name: "Sommer", country_location_id: country.id)

    # School year 2025/2026
    vacation(federal_state, herbst, ~D[2025-10-13], ~D[2025-10-24])
    vacation(federal_state, oster, ~D[2026-03-30], ~D[2026-04-10])
    vacation(federal_state, sommer, ~D[2026-06-29], ~D[2026-08-07])

    # School year 2026/2027
    vacation(federal_state, herbst, ~D[2026-10-12], ~D[2026-10-23])

    {:ok, country: country, school: school}
  end

  describe "in the middle of the Sommerferien" do
    setup %{conn: conn, country: country, school: school} do
      conn = get(conn, ~p"/ferien/#{country.slug}/schule/#{school.slug}?today=25.07.2026")
      {:ok, html: html_response(conn, 200)}
    end

    test "the title advertises the new school year", %{html: html} do
      assert html =~ "Ferien & freie Tage 2026/2027"
      refute html =~ "Ferien & freie Tage 2025/2026"
    end

    test "the finished dates are collapsed but still in the markup", %{html: html} do
      assert html =~ "vergangene Termine anzeigen"
      assert html =~ "30.03.2026"
    end

    test "the old school year is no longer labelled as current", %{html: html} do
      assert html =~ "Läuft noch"
      refute html =~ ">\n                  Aktuell"
    end

    test "past periods are not marked up as schema.org events", %{html: html} do
      events = json_ld_events(html)

      assert Enum.any?(events, &(&1["endDate"] == "2026-08-07"))
      refute Enum.any?(events, &(&1["endDate"] == "2026-04-10"))
    end

    test "the calendar view skips the months that are over", %{html: html} do
      assert html =~ "juli2026"
      refute html =~ "oktober2025"
      refute html =~ "maerz2026"
    end
  end

  describe "while the school year is still running" do
    setup %{conn: conn, country: country, school: school} do
      conn = get(conn, ~p"/ferien/#{country.slug}/schule/#{school.slug}?today=15.05.2026")
      {:ok, html: html_response(conn, 200)}
    end

    test "the title still advertises the running school year", %{html: html} do
      assert html =~ "Ferien & freie Tage 2025/2026"
    end

    test "the school year keeps its Aktuell badge", %{html: html} do
      assert html =~ "Aktuell"
      refute html =~ "Läuft noch"
    end

    test "only the dates that are over are collapsed", %{html: html} do
      # Herbstferien and Osterferien are done, the Sommerferien are not
      assert html =~ "2 vergangene Termine anzeigen"
    end
  end

  defp vacation(location, type, starts_on, ends_on) do
    insert(:period,
      location_id: location.id,
      holiday_or_vacation_type_id: type.id,
      starts_on: starts_on,
      ends_on: ends_on,
      is_school_vacation: true,
      is_valid_for_students: true,
      is_public_holiday: false
    )
  end

  defp json_ld_events(html) do
    ~r|<script type="application/ld\+json">\s*(.*?)\s*</script>|s
    |> Regex.scan(html)
    |> Enum.map(fn [_, json] -> Jason.decode!(json) end)
    |> Enum.filter(&(&1["@type"] == "Event"))
  end
end
