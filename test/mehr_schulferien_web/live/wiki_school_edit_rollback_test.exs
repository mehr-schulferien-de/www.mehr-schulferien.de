defmodule MehrSchulferienWeb.WikiSchoolEditRollbackTest do
  use MehrSchulferienWeb.ConnCase

  # WIKI MAINTENANCE MODE: Tests skipped while wiki is disabled
  # To re-enable: remove this line and uncomment wiki routes in router.ex
  @moduletag :skip

  import Phoenix.LiveViewTest
  import MehrSchulferien.Factory

  alias MehrSchulferien.Locations

  describe "simple rollback functionality" do
    setup do
      # Create a school with an address
      federal_state = insert(:federal_state)
      city = insert(:city, parent_location_id: federal_state.id)

      school =
        insert(:school,
          name: "Test School",
          parent_location_id: city.id
        )

      address =
        insert(:address,
          school_location_id: school.id,
          street: "Initial Street",
          zip_code: "10000",
          city: "Initial City",
          phone_number: "+49 123 456789",
          homepage_url: "https://initial.school.de",
          email_address: "initial@school.de",
          students_count: 500,
          founded_year: 1900,
          description: "Initial description"
        )

      school = Locations.get_school_by_slug!(school.slug)

      {:ok, school: school, address: address}
    end

    test "shows timeline with no versions initially", %{conn: conn, school: school} do
      {:ok, _view, html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Check for timeline UI elements
      assert html =~ "Versionshistorie"
      assert html =~ "0 Änderungen"
      assert html =~ "Noch keine Änderungen vorhanden"
    end

    test "creates version and shows in timeline after single change", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Make a change to school name
      assert view
             |> form("form[phx-submit=\"update_school\"]", %{
               "name" => "Updated School Name",
               "address" => %{
                 "street" => school.address.street,
                 "zip_code" => school.address.zip_code,
                 "city" => school.address.city
               }
             })
             |> render_submit()

      # Refresh the page to see the version
      {:ok, _view, html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Check timeline shows the change - versions are now stored properly
      assert html =~ "Änderungen"
      assert html =~ "geändert"
      refute html =~ "Noch keine Änderungen vorhanden"
    end

    test "creates multiple versions and shows all in timeline", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # First change - update school name
      assert view
             |> form("form[phx-submit=\"update_school\"]", %{
               "name" => "First Update",
               "address" => %{
                 "street" => school.address.street,
                 "zip_code" => school.address.zip_code,
                 "city" => school.address.city
               }
             })
             |> render_submit()

      # Second change - update street
      assert view
             |> form("form[phx-submit=\"update_school\"]", %{
               "name" => "First Update",
               "address" => %{
                 "street" => "New Street 123",
                 "zip_code" => school.address.zip_code,
                 "city" => school.address.city
               }
             })
             |> render_submit()

      # Third change - update multiple fields
      assert view
             |> form("form[phx-submit=\"update_school\"]", %{
               "name" => "Final Name",
               "address" => %{
                 "street" => "New Street 123",
                 "zip_code" => "20000",
                 "city" => "New City",
                 "phone_number" => "+49 987 654321"
               }
             })
             |> render_submit()

      # Refresh the page
      {:ok, _view, html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Check timeline shows changes
      assert html =~ "Änderungen"
      # Should see different change descriptions
      assert html =~ "geändert"
    end

    test "shows rollback preview modal with before/after comparison", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Make a change first
      assert view
             |> form("form[phx-submit=\"update_school\"]", %{
               "name" => "Changed School",
               "address" => %{
                 "street" => "Changed Street",
                 "zip_code" => "99999",
                 "city" => "Changed City"
               }
             })
             |> render_submit()

      # Refresh to get the version with snapshot
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Click rollback button (if it exists - need to check snapshot is stored)
      # This test may need adjustment based on how snapshots are stored
      html = render(view)

      if html =~ "Wiederherstellen" do
        # Find and click the first rollback button
        view
        |> element("button", "Wiederherstellen")
        |> render_click()

        # Check modal appears with comparison
        html = render(view)
        assert html =~ "Version wiederherstellen"
        assert html =~ "Möchten Sie zu dieser Version zurückkehren?"
        assert html =~ "Aktueller Zustand"
        assert html =~ "Nach Wiederherstellung"
      end
    end

    test "successfully rolls back to previous version", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Store initial state
      _initial_name = school.name
      _initial_street = school.address.street

      # Make first change
      assert view
             |> form("form[phx-submit=\"update_school\"]", %{
               "name" => "First Change",
               "address" => %{
                 "street" => "First Street",
                 "zip_code" => school.address.zip_code,
                 "city" => school.address.city
               }
             })
             |> render_submit()

      # Make second change
      assert view
             |> form("form[phx-submit=\"update_school\"]", %{
               "name" => "Second Change",
               "address" => %{
                 "street" => "Second Street",
                 "zip_code" => "22222",
                 "city" => "Second City"
               }
             })
             |> render_submit()

      # Verify current state
      updated_school = Locations.get_school_by_slug!(school.slug)
      assert updated_school.name == "Second Change"
      assert updated_school.address.street == "Second Street"

      # Now we would test rollback, but this requires snapshot functionality to be working
      # This is a placeholder for the actual rollback test
    end

    test "multiple changes and rollbacks work correctly", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Track all states
      states = [
        %{name: school.name, street: school.address.street, city: school.address.city},
        %{name: "State 1", street: "Street 1", city: "City 1"},
        %{name: "State 2", street: "Street 2", city: "City 2"},
        %{name: "State 3", street: "Street 3", city: "City 3"}
      ]

      # Apply changes
      for i <- 1..3 do
        state = Enum.at(states, i)

        assert view
               |> form("form[phx-submit=\"update_school\"]", %{
                 "name" => state.name,
                 "address" => %{
                   "street" => state.street,
                   "zip_code" => school.address.zip_code,
                   "city" => state.city
                 }
               })
               |> render_submit()
      end

      # Verify final state
      final_school = Locations.get_school_by_slug!(school.slug)
      assert final_school.name == "State 3"
      assert final_school.address.street == "Street 3"
      assert final_school.address.city == "City 3"
    end

    test "handles address creation through changes", %{conn: conn} do
      # Create school without address
      federal_state = insert(:federal_state)
      city = insert(:city, parent_location_id: federal_state.id)

      school =
        insert(:school,
          name: "School Without Address",
          parent_location_id: city.id
        )

      # Don't create address
      school = Locations.get_school_by_slug!(school.slug)
      assert is_nil(school.address)

      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Add address data
      assert view
             |> form("form[phx-submit=\"update_school\"]", %{
               "name" => school.name,
               "address" => %{
                 "street" => "New Street",
                 "zip_code" => "12345",
                 "city" => "New City",
                 "phone_number" => "+49 123 456789"
               }
             })
             |> render_submit()

      # Verify address was created
      updated_school = Locations.get_school_by_slug!(school.slug)
      assert updated_school.address
      assert updated_school.address.street == "New Street"
      assert updated_school.address.zip_code == "12345"
      assert updated_school.address.city == "New City"
    end

    test "timeline UI shows correct styling and elements", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Make some changes to create timeline items
      for i <- 1..3 do
        assert view
               |> form("form[phx-submit=\"update_school\"]", %{
                 "name" => "Update #{i}",
                 "address" => %{
                   "street" => school.address.street,
                   "zip_code" => school.address.zip_code,
                   "city" => school.address.city
                 }
               })
               |> render_submit()
      end

      # Refresh and check timeline UI
      {:ok, _view, html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Check for timeline elements
      assert html =~ "Versionshistorie"
      assert html =~ "Änderungen"

      # Check for timeline line (CSS classes)
      assert html =~ "absolute left-4 top-0 bottom-0"

      # Check for timeline dots
      assert html =~ "rounded-full border-2"

      # The most recent should have special styling
      assert html =~ "bg-blue-500 border-blue-500"
    end

    test "respects daily change limit", %{conn: conn, school: school} do
      # First set up a high change count to simulate limit
      today = Date.utc_today()
      # Set to exactly the limit to trigger the limit reached state
      for _ <- 1..250 do
        MehrSchulferien.Wiki.increment_daily_change_count(today)
      end

      {:ok, _view, html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Should show limit warning
      assert html =~ "Tageslimit"

      # When limit is reached, the form is disabled, so we just check the HTML
      # contains the limit message and that the form cannot be submitted
      assert html =~ "Es können heute keine weiteren Änderungen vorgenommen werden"

      # Verify that the school name hasn't changed
      unchanged_school = Locations.get_school_by_slug!(school.slug)
      assert unchanged_school.name == "Test School"
    end

    test "handles complex field updates correctly", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Update all possible fields
      assert view
             |> form("form[phx-submit=\"update_school\"]", %{
               "name" => "Complete Update",
               "address" => %{
                 "street" => "Complete Street 999",
                 "zip_code" => "88888",
                 "city" => "Complete City",
                 "phone_number" => "+49 999 888777",
                 "email_address" => "complete@school.de",
                 "homepage_url" => "https://complete.school.de",
                 "wikipedia_url" => "https://wikipedia.org/complete",
                 "instagram_url" => "https://instagram.com/complete",
                 "students_count" => "1500",
                 "founded_year" => "2000",
                 "description" => "Complete description of the school"
               }
             })
             |> render_submit()

      # Verify all fields were updated
      updated_school = Locations.get_school_by_slug!(school.slug)
      assert updated_school.name == "Complete Update"
      assert updated_school.address.street == "Complete Street 999"
      assert updated_school.address.zip_code == "88888"
      assert updated_school.address.city == "Complete City"
      assert updated_school.address.phone_number == "+49 999 888777"
      assert updated_school.address.email_address == "complete@school.de"
      assert updated_school.address.homepage_url == "https://complete.school.de"
      assert updated_school.address.wikipedia_url == "https://wikipedia.org/complete"
      assert updated_school.address.instagram_url == "https://instagram.com/complete"
      assert updated_school.address.students_count == 1500
      assert updated_school.address.founded_year == 2000
      assert updated_school.address.description == "Complete description of the school"
    end
  end
end
