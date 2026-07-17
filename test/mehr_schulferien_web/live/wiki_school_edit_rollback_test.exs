defmodule MehrSchulferienWeb.WikiSchoolEditRollbackTest do
  use MehrSchulferienWeb.ConnCase

  import Phoenix.LiveViewTest
  import MehrSchulferien.Factory

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Wiki.PendingChanges

  describe "school edit approval workflow and version timeline" do
    setup [:log_in_wiki_user]

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

    test "queues a change, applies it on approval and shows the version in the timeline", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Make a change to school name - it gets queued, not applied
      view
      |> form("form[phx-submit=\"update_school\"]", %{
        "name" => "Updated School Name",
        "address" => %{
          "street" => school.address.street,
          "zip_code" => school.address.zip_code,
          "city" => school.address.city
        }
      })
      |> render_submit()

      flash = assert_redirect(view, "/wiki")

      assert flash["info"] ==
               "Ihre Änderung wurde zur Überprüfung eingereicht. Sie wird nach Genehmigung auf der Seite sichtbar."

      # Nothing changed yet and no version was recorded
      assert Locations.get_school_by_slug!(school.slug).name == "Test School"

      {:ok, _view, html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")
      assert html =~ "Noch keine Änderungen vorhanden"

      # Approve the queued change
      [pending_change] = PendingChanges.list_pending()
      assert pending_change.change_type == "update_school"
      assert pending_change.original_record_id == school.id
      assert pending_change.payload["school_name"] == "Updated School Name"

      {:ok, %{school: updated_school}} = PendingChanges.approve_change!(pending_change)
      assert updated_school.name == "Updated School Name"

      # Timeline now shows the change
      {:ok, _view, html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")
      assert html =~ "geändert"
      refute html =~ "Noch keine Änderungen vorhanden"
    end

    test "multiple approved changes appear in the timeline", %{conn: conn, school: school} do
      # First change - update school name
      submit_and_approve_edit(conn, school.slug, "First Update", %{
        "street" => school.address.street,
        "zip_code" => school.address.zip_code,
        "city" => school.address.city
      })

      # Second change - update street
      submit_and_approve_edit(conn, school.slug, "First Update", %{
        "street" => "New Street 123",
        "zip_code" => school.address.zip_code,
        "city" => school.address.city
      })

      # Third change - update multiple fields
      %{school: final_school} =
        submit_and_approve_edit(conn, school.slug, "Final Name", %{
          "street" => "New Street 123",
          "zip_code" => "20000",
          "city" => "New City",
          "phone_number" => "+49 987 654321"
        })

      assert final_school.name == "Final Name"
      assert final_school.address.street == "New Street 123"
      assert final_school.address.zip_code == "20000"

      # Timeline shows the changes
      {:ok, _view, html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")
      assert html =~ "Änderungen"
      assert html =~ "geändert"
      refute html =~ "Noch keine Änderungen vorhanden"
    end

    test "does not offer rollback for approved versions without snapshot", %{
      conn: conn,
      school: school
    } do
      # Queue and approve a change so a version exists
      submit_and_approve_edit(conn, school.slug, "Changed School", %{
        "street" => "Changed Street",
        "zip_code" => "99999",
        "city" => "Changed City"
      })

      {:ok, view, html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # The version is in the timeline, but versions created via the approval
      # workflow carry no snapshot, so no restore button is offered
      assert html =~ "geändert"
      refute html =~ "Wiederherstellen"

      # Even triggering the rollback flow directly is refused without a snapshot
      updated_school = Locations.get_school_by_slug!(school.slug)
      [version | _] = PaperTrail.get_versions(updated_school)

      render_click(view, "show_rollback_preview", %{"version_id" => to_string(version.id)})

      html = render(view)
      assert html =~ "Version wiederherstellen"
      assert html =~ "Möchten Sie zu dieser Version zurückkehren?"

      render_click(view, "confirm_rollback", %{"version_id" => to_string(version.id)})

      assert render(view) =~ "Version konnte nicht wiederhergestellt werden."

      # State is unchanged by the refused rollback
      assert Locations.get_school_by_slug!(school.slug).name == "Changed School"
    end

    test "queued changes apply only after approval, preserving order", %{
      conn: conn,
      school: school
    } do
      # First edit is queued - nothing applied yet
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      view
      |> form("form[phx-submit=\"update_school\"]", %{
        "name" => "First Change",
        "address" => %{
          "street" => "First Street",
          "zip_code" => school.address.zip_code,
          "city" => school.address.city
        }
      })
      |> render_submit()

      assert_redirect(view, "/wiki")

      unchanged = Locations.get_school_by_slug!(school.slug)
      assert unchanged.name == "Test School"
      assert unchanged.address.street == "Initial Street"

      # Approve the first change
      [first_pending] = PendingChanges.list_pending()
      {:ok, %{school: after_first}} = PendingChanges.approve_change!(first_pending)
      assert after_first.name == "First Change"
      assert after_first.address.street == "First Street"

      # Second edit, queued and approved
      %{school: after_second} =
        submit_and_approve_edit(conn, school.slug, "Second Change", %{
          "street" => "Second Street",
          "zip_code" => "22222",
          "city" => "Second City"
        })

      assert after_second.name == "Second Change"
      assert after_second.address.street == "Second Street"
      assert after_second.address.zip_code == "22222"
      assert after_second.address.city == "Second City"
    end

    test "sequential queued changes apply in order", %{conn: conn, school: school} do
      # Track all states
      states = [
        %{name: school.name, street: school.address.street, city: school.address.city},
        %{name: "State 1", street: "Street 1", city: "City 1"},
        %{name: "State 2", street: "Street 2", city: "City 2"},
        %{name: "State 3", street: "Street 3", city: "City 3"}
      ]

      # Apply changes, each one queued and approved
      for i <- 1..3 do
        state = Enum.at(states, i)

        submit_and_approve_edit(conn, school.slug, state.name, %{
          "street" => state.street,
          "zip_code" => school.address.zip_code,
          "city" => state.city
        })
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

      # Add address data - queued for approval
      view
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

      assert_redirect(view, "/wiki")

      # No address exists before approval
      assert is_nil(Locations.get_school_by_slug!(school.slug).address)

      [pending_change] = PendingChanges.list_pending()
      assert pending_change.change_type == "update_school"

      # Approving creates the address
      {:ok, %{school: updated_school}} = PendingChanges.approve_change!(pending_change)
      assert updated_school.address
      assert updated_school.address.street == "New Street"
      assert updated_school.address.zip_code == "12345"
      assert updated_school.address.city == "New City"
    end

    test "timeline UI shows correct styling and elements", %{conn: conn, school: school} do
      # Make some changes (queued and approved) to create timeline items
      for i <- 1..3 do
        submit_and_approve_edit(conn, school.slug, "Update #{i}", %{
          "street" => school.address.street,
          "zip_code" => school.address.zip_code,
          "city" => school.address.city
        })
      end

      # Check timeline UI
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

      # Update all possible fields - queued for approval
      view
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

      assert_redirect(view, "/wiki")

      [pending_change] = PendingChanges.list_pending()
      assert pending_change.change_type == "update_school"
      assert pending_change.payload["school_name"] == "Complete Update"
      assert pending_change.payload["address_params"]["street"] == "Complete Street 999"

      # Nothing is applied before approval
      assert Locations.get_school_by_slug!(school.slug).name == "Test School"

      {:ok, %{school: updated_school}} = PendingChanges.approve_change!(pending_change)

      # Verify all fields were updated after approval
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

  # Submits a school edit via the LiveView form, asserts it is queued as a
  # pending change and approves it. Returns the approve result
  # (%{school: school, address: address}).
  defp submit_and_approve_edit(conn, school_slug, name, address_attrs) do
    {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school_slug}/edit")

    view
    |> form("form[phx-submit=\"update_school\"]", %{
      "name" => name,
      "address" => address_attrs
    })
    |> render_submit()

    flash = assert_redirect(view, "/wiki")

    assert flash["info"] ==
             "Ihre Änderung wurde zur Überprüfung eingereicht. Sie wird nach Genehmigung auf der Seite sichtbar."

    [pending_change] = PendingChanges.list_pending()
    assert pending_change.change_type == "update_school"
    assert pending_change.payload["school_name"] == name

    {:ok, result} = PendingChanges.approve_change!(pending_change)
    result
  end
end
