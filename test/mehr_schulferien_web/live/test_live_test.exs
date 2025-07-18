defmodule MehrSchulferienWeb.TestLiveTest do
  use MehrSchulferienWeb.ConnCase

  import Phoenix.LiveViewTest
  import MehrSchulferien.Factory

  setup do
    # Create Germany country that the TestLive expects
    country = insert(:country, name: "Deutschland", slug: "d", code: "DE")

    # Create some federal states
    bayern =
      insert(:federal_state,
        name: "Bayern",
        slug: "bayern",
        parent_location_id: country.id
      )

    hamburg =
      insert(:federal_state,
        name: "Hamburg",
        slug: "hamburg",
        parent_location_id: country.id
      )

    {:ok, country: country, bayern: bayern, hamburg: hamburg}
  end

  describe "mount and initial state" do
    test "mounts successfully and shows initial form", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/test")

      assert html =~ "Schulferien und Feiertage"
      assert html =~ "Bundesland"
      assert html =~ "Stadt oder PLZ"
      assert html =~ "Schulname"
      assert html =~ "Alle Bundesländer"
    end
  end

  describe "federal state selection" do
    test "selecting a federal state loads cities and schools", %{
      conn: conn,
      bayern: federal_state
    } do
      # Create test data
      county =
        insert(:county,
          name: "München",
          parent_location_id: federal_state.id
        )

      city =
        insert(:city,
          name: "München",
          slug: "muenchen",
          parent_location_id: county.id
        )

      # Create schools with addresses
      school1 =
        insert(:school,
          name: "Gymnasium München Nord",
          parent_location_id: city.id
        )

      insert(:address,
        school_location_id: school1.id,
        street: "Nordstraße 1",
        zip_code: "80331"
      )

      school2 =
        insert(:school,
          name: "Realschule München Süd",
          parent_location_id: city.id
        )

      insert(:address,
        school_location_id: school2.id,
        street: "Südstraße 2",
        zip_code: "80333"
      )

      {:ok, view, _html} = live(conn, "/test")

      # Select the federal state
      # Trigger the form change
      view
      |> form("form", search: %{federal_state_id: to_string(federal_state.id)})
      |> render_change()

      # Get the full rendered HTML from the view
      html = render(view)

      # Should show federal state name
      assert html =~ "Bayern"

      # Should show statistics in the federal state overview (formatted numbers)
      assert html =~ "1 Stadt" || html =~ "1 Städte"
      assert html =~ "2 Schulen"

      # Should show city and schools
      assert html =~ "München"
      assert html =~ "2 Schulen"
      assert html =~ "PLZ-Bereich: 80331 und 80333"

      # Should show school names
      assert html =~ "Gymnasium München Nord"
      assert html =~ "Realschule München Süd"

      # Should show addresses
      assert html =~ "Nordstraße 1"
      assert html =~ "Südstraße 2"
    end
  end

  describe "location search" do
    test "searching by zip code shows schools in that zip code", %{conn: conn, country: country} do
      # Create test data
      federal_state =
        insert(:federal_state,
          name: "Rheinland-Pfalz",
          slug: "rheinland-pfalz",
          parent_location_id: country.id
        )

      county =
        insert(:county,
          name: "Koblenz",
          parent_location_id: federal_state.id
        )

      city =
        insert(:city,
          name: "Koblenz",
          slug: "koblenz",
          parent_location_id: county.id
        )

      # Create schools with specific zip code
      school1 =
        insert(:school,
          name: "Gymnasium Koblenz",
          parent_location_id: city.id
        )

      insert(:address,
        school_location_id: school1.id,
        street: "Hauptstraße 1",
        zip_code: "56068"
      )

      school2 =
        insert(:school,
          name: "Realschule Koblenz",
          parent_location_id: city.id
        )

      insert(:address,
        school_location_id: school2.id,
        street: "Nebenstraße 2",
        zip_code: "56068"
      )

      # Create a school in different zip code (should not appear)
      school3 =
        insert(:school,
          name: "Hauptschule Koblenz",
          parent_location_id: city.id
        )

      insert(:address,
        school_location_id: school3.id,
        street: "Andere Straße 3",
        zip_code: "56070"
      )

      {:ok, view, _html} = live(conn, "/test")

      # Enter zip code in location field
      html =
        view
        |> form("form", search: %{location: "56068"})
        |> render_change()

      # Should show search results header
      assert html =~ "Suchergebnisse für PLZ 56068"

      # Should auto-select federal state
      assert html =~ "Rheinland-Pfalz"

      # Should show city
      assert html =~ "Koblenz"

      # Should show only schools in that zip code
      assert html =~ "Gymnasium Koblenz"
      assert html =~ "Realschule Koblenz"
      refute html =~ "Hauptschule Koblenz"

      # Should show city name in results
      assert html =~ "Koblenz"
    end

    test "searching by zip code and school name filters results", %{conn: conn, country: country} do
      # Create test data
      federal_state =
        insert(:federal_state,
          name: "Rheinland-Pfalz",
          slug: "rheinland-pfalz",
          parent_location_id: country.id
        )

      county =
        insert(:county,
          name: "Koblenz",
          parent_location_id: federal_state.id
        )

      city =
        insert(:city,
          name: "Koblenz",
          slug: "koblenz",
          parent_location_id: county.id
        )

      # Create schools with same zip code but different names
      school1 =
        insert(:school,
          name: "Gymnasium am Rhein",
          parent_location_id: city.id
        )

      insert(:address,
        school_location_id: school1.id,
        street: "Rheinstraße 1",
        zip_code: "56068"
      )

      school2 =
        insert(:school,
          name: "Realschule Koblenz",
          parent_location_id: city.id
        )

      insert(:address,
        school_location_id: school2.id,
        street: "Schulstraße 2",
        zip_code: "56068"
      )

      school3 =
        insert(:school,
          name: "Gymnasium Asterstein",
          parent_location_id: city.id
        )

      insert(:address,
        school_location_id: school3.id,
        street: "Bergstraße 3",
        zip_code: "56068"
      )

      {:ok, view, _html} = live(conn, "/test")

      # First enter zip code
      view
      |> form("form", search: %{location: "56068"})
      |> render_change()

      # Then add school name filter
      view
      |> form("form", search: %{location: "56068", school_name: "Gymnasium"})
      |> render_change()

      # Get the full rendered HTML from the view
      html = render(view)

      # Should show filtered search results header
      # HTML encodes quotes as &quot;
      assert html =~ "Suchergebnisse für &quot;Gymnasium&quot; in 56068" ||
               html =~ "Suchergebnisse für &quot;Gymnasium&quot; in PLZ 56068"

      # Should show only schools matching "Gymnasium"
      assert html =~ "Gymnasium am Rhein"
      assert html =~ "Gymnasium Asterstein"
      refute html =~ "Realschule Koblenz"

      # Should show the prominent result counter with found schools
      assert html =~ "2 Schulen gefunden" || html =~ "2 gefundene Schulen"

      # Should show correct city count
      assert html =~ "in 1 Stadt"
    end
  end

  describe "city search" do
    test "searching by city name shows schools in that city", %{conn: conn, country: country} do
      # Create test data
      federal_state =
        insert(:federal_state,
          name: "Berlin",
          slug: "berlin",
          parent_location_id: country.id
        )

      county =
        insert(:county,
          name: "Berlin",
          parent_location_id: federal_state.id
        )

      city =
        insert(:city,
          name: "Berlin",
          slug: "berlin",
          parent_location_id: county.id
        )

      # Create schools
      school1 =
        insert(:school,
          name: "Gymnasium Berlin Mitte",
          parent_location_id: city.id
        )

      insert(:address,
        school_location_id: school1.id,
        street: "Hauptstraße 1",
        zip_code: "10115"
      )

      school2 =
        insert(:school,
          name: "Realschule Berlin",
          parent_location_id: city.id
        )

      insert(:address,
        school_location_id: school2.id,
        street: "Nebenstraße 2",
        zip_code: "10117"
      )

      {:ok, view, _html} = live(conn, "/test")

      # Enter city name in location field
      html =
        view
        |> form("form", search: %{location: "Berlin"})
        |> render_change()

      # Should show search results
      assert html =~ "Suchergebnisse für Berlin"

      # Should show schools
      assert html =~ "Gymnasium Berlin Mitte"
      assert html =~ "Realschule Berlin"
    end
  end
end
