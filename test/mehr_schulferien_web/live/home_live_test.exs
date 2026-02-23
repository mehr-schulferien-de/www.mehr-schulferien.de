defmodule MehrSchulferienWeb.HomeLiveTest do
  use MehrSchulferienWeb.ConnCase

  import Phoenix.LiveViewTest
  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  setup do
    # Create Germany country that the HomeLive expects
    country = get_or_create_deutschland()

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
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Schulferien Deutschland"
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

      {:ok, view, _html} = live(conn, "/")

      # Select the federal state
      # Trigger the form change
      view
      |> form("form", search: %{federal_state_id: to_string(federal_state.id)})
      |> render_change()

      # Get the full rendered HTML from the view
      html = render(view)

      # Should show federal state name
      assert html =~ "Bayern"

      # Should show single city statistics (only 1 city was created)
      # Should show federal state name again
      assert html =~ "Bayern"

      # Should show city
      assert html =~ "München"

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

      {:ok, view, _html} = live(conn, "/")

      # Enter zip code in location field
      html =
        view
        |> form("form", search: %{location: "56068"})
        |> render_change()

      # Should show search results header
      assert html =~ "Suchergebnisse für" && html =~ "PLZ 56068"

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

      # Create additional cities to make the statistics section appear
      city2 =
        insert(:city,
          name: "Mainz",
          slug: "mainz",
          parent_location_id: county.id
        )

      city3 =
        insert(:city,
          name: "Trier",
          slug: "trier",
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

      # Create schools in other cities with same zip code to make multiple cities appear
      school4 =
        insert(:school,
          name: "Gymnasium Mainz",
          parent_location_id: city2.id
        )

      insert(:address,
        school_location_id: school4.id,
        street: "Hauptstraße 10",
        zip_code: "56068"
      )

      school5 =
        insert(:school,
          name: "Realschule Trier",
          parent_location_id: city3.id
        )

      insert(:address,
        school_location_id: school5.id,
        street: "Schulweg 5",
        zip_code: "56068"
      )

      {:ok, view, _html} = live(conn, "/")

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
      assert html =~ "Suchergebnisse für &quot;Gymnasium&quot; in" && html =~ "PLZ 56068"

      # Should show only schools matching "Gymnasium"
      assert html =~ "Gymnasium am Rhein"
      assert html =~ "Gymnasium Asterstein"
      refute html =~ "Realschule Koblenz"

      # Should show the prominent result counter with found schools
      # With multiple cities (3 created), it should show the statistics
      assert html =~ "Städte"
      assert html =~ "Schulen gesamt"
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

      {:ok, view, _html} = live(conn, "/")

      # Enter city name in location field
      html =
        view
        |> form("form", search: %{location: "Berlin"})
        |> render_change()

      # Should show search results
      assert html =~ "Suchergebnisse für" && html =~ "&quot;Berlin&quot;"

      # Should show schools
      assert html =~ "Gymnasium Berlin Mitte"
      assert html =~ "Realschule Berlin"
    end
  end
end
