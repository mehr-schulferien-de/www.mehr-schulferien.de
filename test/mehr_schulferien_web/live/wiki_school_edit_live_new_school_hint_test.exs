defmodule MehrSchulferienWeb.WikiSchoolEditLiveNewSchoolHintTest do
  use MehrSchulferienWeb.ConnCase, async: true

  # WIKI MAINTENANCE MODE: Tests skipped while wiki is disabled
  # To re-enable: remove this line and uncomment wiki routes in router.ex
  @moduletag :skip

  import Phoenix.LiveViewTest
  import MehrSchulferien.Factory

  describe "new school hint when zip code changes" do
    setup do
      # Create a country, federal state, county and city hierarchy using proper factories
      country = insert(:country, %{name: "Deutschland", slug: "d"})

      federal_state =
        insert(:federal_state, %{
          name: "Bayern",
          slug: "bayern",
          parent_location_id: country.id
        })

      county =
        insert(:county, %{
          name: "München (Kreis)",
          slug: "muenchen-kreis",
          parent_location_id: federal_state.id
        })

      # Create a city with a zip code
      city =
        insert(:city, %{
          name: "München",
          slug: "muenchen",
          parent_location_id: county.id
        })

      zip_code = insert(:zip_code, %{value: "80331", country_location_id: country.id})

      _zip_code_mapping =
        insert(:zip_code_mapping, %{location_id: city.id, zip_code_id: zip_code.id})

      # Create another city with different zip code
      city2 =
        insert(:city, %{
          name: "Nürnberg",
          slug: "nuernberg",
          parent_location_id: county.id
        })

      zip_code2 = insert(:zip_code, %{value: "90402", country_location_id: country.id})

      _zip_code_mapping2 =
        insert(:zip_code_mapping, %{location_id: city2.id, zip_code_id: zip_code2.id})

      # Create a school
      school =
        insert(:school, %{
          name: "Test Gymnasium München",
          slug: "80331-test-gymnasium-muenchen",
          parent_location_id: city.id
        })

      address =
        insert(:address, %{
          school_location_id: school.id,
          line1: "Test Gymnasium München",
          street: "Marienplatz 1",
          zip_code: "80331",
          city: "München"
        })

      school = %{school | address: address}

      %{school: school, zip_code: zip_code, zip_code2: zip_code2, city: city, city2: city2}
    end

    test "shows hint when zip code is changed", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Initially, the new school hint should not be visible
      refute has_element?(view, "#new-school-hint")

      # Change the zip code to a different one
      view
      |> form("form", %{
        "address" => %{"zip_code" => "90402"},
        "name" => school.name
      })
      |> render_change()

      # Now the hint should be visible
      assert has_element?(view, "#new-school-hint")
      assert render(view) =~ "Möchten Sie eine neue Schule anlegen?"
    end

    test "shows link to add new school in hint", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Change the zip code
      view
      |> form("form", %{
        "address" => %{"zip_code" => "90402"},
        "name" => school.name
      })
      |> render_change()

      # Check that the link to add a new school is present
      assert has_element?(view, "a[href='/wiki/schools/new']")
    end

    test "hides hint when zip code is changed back to original", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Change the zip code
      view
      |> form("form", %{
        "address" => %{"zip_code" => "90402"},
        "name" => school.name
      })
      |> render_change()

      # Hint should be visible
      assert has_element?(view, "#new-school-hint")

      # Change back to original zip code
      view
      |> form("form", %{
        "address" => %{"zip_code" => "80331"},
        "name" => school.name
      })
      |> render_change()

      # Hint should be hidden again
      refute has_element?(view, "#new-school-hint")
    end

    test "does not show hint for small changes to zip code", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Type partial zip code (not complete)
      view
      |> form("form", %{
        "address" => %{"zip_code" => "8033"},
        "name" => school.name
      })
      |> render_change()

      # Hint should not be visible for incomplete zip codes
      refute has_element?(view, "#new-school-hint")
    end
  end

  describe "add new school link visibility" do
    setup do
      # Create a country, federal state, county and city hierarchy using proper factories
      country = insert(:country, %{name: "Deutschland", slug: "d2"})

      federal_state =
        insert(:federal_state, %{
          name: "Bayern",
          slug: "bayern2",
          parent_location_id: country.id
        })

      county =
        insert(:county, %{
          name: "München (Kreis)",
          slug: "muenchen-kreis2",
          parent_location_id: federal_state.id
        })

      city =
        insert(:city, %{
          name: "München",
          slug: "muenchen2",
          parent_location_id: county.id
        })

      zip_code = insert(:zip_code, %{value: "80332", country_location_id: country.id})

      _zip_code_mapping =
        insert(:zip_code_mapping, %{location_id: city.id, zip_code_id: zip_code.id})

      school =
        insert(:school, %{
          name: "Test Gymnasium",
          slug: "80332-test-gymnasium",
          parent_location_id: city.id
        })

      address =
        insert(:address, %{
          school_location_id: school.id,
          line1: "Test Gymnasium",
          street: "Teststraße 1",
          zip_code: "80332",
          city: "München"
        })

      school = %{school | address: address}

      %{school: school}
    end

    test "shows prominent 'Add New School' button in sidebar", %{conn: conn, school: school} do
      {:ok, _view, html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Check that there's a visible link to add a new school
      assert html =~ "Neue Schule anlegen"
      assert html =~ "/wiki/schools/new"
    end
  end
end
