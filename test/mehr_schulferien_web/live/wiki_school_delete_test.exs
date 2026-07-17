defmodule MehrSchulferienWeb.WikiSchoolDeleteTest do
  use MehrSchulferienWeb.ConnCase

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias MehrSchulferien.{Locations, Repo}
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Maps.Address
  alias MehrSchulferien.Wiki.PendingChanges

  describe "school deletion" do
    setup [:log_in_wiki_user]

    setup do
      # Create a simple school with address manually to avoid factory issues
      {:ok, city} =
        %Location{
          name: "Test City",
          slug: "test-city",
          is_city: true
        }
        |> Repo.insert()

      {:ok, school} =
        %Location{
          name: "Test Grundschule",
          slug: "test-grundschule-#{System.unique_integer([:positive])}",
          is_school: true,
          parent_location_id: city.id
        }
        |> Repo.insert()

      {:ok, address} =
        %Address{
          school_location_id: school.id,
          line1: school.name,
          street: "Teststraße 123",
          zip_code: "12345",
          city: "Test City",
          email_address: "test@schule.de",
          phone_number: "030-123456",
          homepage_url: "https://test-schule.de"
        }
        |> Repo.insert()

      %{
        school: school,
        address: address,
        city: city
      }
    end

    test "shows delete button in danger zone", %{conn: conn, school: school} do
      {:ok, _view, html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      assert html =~ "Gefahrenzone"
      assert html =~ "Schule löschen"
      assert html =~ "Diese Aktion kann nicht rückgängig gemacht werden"
    end

    test "opens delete confirmation modal when delete button is clicked", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Click delete button
      assert view
             |> element("button", "Schule löschen")
             |> render_click()

      # Check modal is shown
      html = render(view)
      assert html =~ "Schule löschen"
      assert html =~ "Sind Sie sicher, dass Sie die Schule"
      assert html =~ school.name
      assert html =~ "Zur Bestätigung geben Sie bitte die Postleitzahl der Schule ein"
      assert html =~ "Grund für die Löschung"
    end

    test "shows ZIP code hint when school has address", %{
      conn: conn,
      school: school,
      address: address
    } do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Open delete modal
      view |> element("button", "Schule löschen") |> render_click()

      # Check ZIP code hint is shown
      html = render(view)
      assert html =~ "(Hinweis: #{address.zip_code})"
    end

    test "cancels deletion when cancel button is clicked", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Open delete modal
      view |> element("button", "Schule löschen") |> render_click()
      assert render(view) =~ "Endgültig löschen"

      # Click cancel
      view |> element("button", "Abbrechen") |> render_click()

      # Modal should be closed
      refute render(view) =~ "Endgültig löschen"
    end

    test "shows error when wrong ZIP code is entered", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Open delete modal
      view |> element("button", "Schule löschen") |> render_click()

      # Submit with wrong ZIP code (target the delete form specifically)
      assert view
             |> element("form[phx-submit=\"confirm_delete\"]")
             |> render_submit(%{
               "zip_code_confirmation" => "99999",
               "deletion_reason" => "Test deletion"
             })

      # Should show error
      html = render(view)
      assert html =~ "Die eingegebene Postleitzahl stimmt nicht überein"

      # School should still exist
      assert Locations.get_school_by_slug!(school.slug)
    end

    test "queues deletion with correct ZIP code and deletes the school after approval", %{
      conn: conn,
      school: school,
      address: address
    } do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Open delete modal
      view |> element("button", "Schule löschen") |> render_click()

      # Submit with correct ZIP code
      assert view
             |> element("form[phx-submit=\"confirm_delete\"]")
             |> render_submit(%{
               "zip_code_confirmation" => address.zip_code,
               "deletion_reason" => "School closed permanently"
             })

      # The delete request goes into the pending-changes queue
      flash = assert_redirect(view, "/wiki")

      assert flash["info"] ==
               "Ihre Löschanfrage wurde zur Überprüfung eingereicht. Sie wird nach Genehmigung umgesetzt."

      # School still exists before approval
      assert Locations.get_school_by_slug!(school.slug)

      [pending_change] = PendingChanges.list_pending()
      assert pending_change.change_type == "delete_school"
      assert pending_change.original_record_id == school.id
      assert pending_change.payload["school_name"] == school.name
      assert pending_change.payload["deletion_reason"] == "School closed permanently"

      # The review notification email was sent on submission
      assert_email_sent(
        subject: "Wiki-Änderung zur Prüfung: Schule löschen: #{school.name}",
        to: {"Stefan Wintermeyer", "sw@wintermeyer-consulting.de"}
      )

      # Approving the change deletes the school
      {:ok, _result} = PendingChanges.approve_change!(pending_change)

      assert_raise Ecto.NoResultsError, fn ->
        Locations.get_school_by_slug!(school.slug)
      end

      # Check backup was created
      deleted_school = Repo.get_by(Locations.DeletedSchool, original_id: school.id)
      assert deleted_school
      assert deleted_school.name == school.name
      assert deleted_school.slug == school.slug
      assert deleted_school.deletion_reason == "School closed permanently"
    end

    test "includes deletion reason in the review notification email", %{
      conn: conn,
      school: school,
      address: address
    } do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Open delete modal and submit
      view |> element("button", "Schule löschen") |> render_click()

      view
      |> element("form[phx-submit=\"confirm_delete\"]")
      |> render_submit(%{
        "zip_code_confirmation" => address.zip_code,
        "deletion_reason" => "Duplicate entry - merged with another school"
      })

      assert_redirect(view, "/wiki")

      # The notification email contains the deletion reason
      assert_email_sent(fn email ->
        assert email.html_body =~ "Löschgrund:"
        assert email.html_body =~ "Duplicate entry - merged with another school"
        assert email.text_body =~ "Löschgrund: Duplicate entry - merged with another school"
      end)
    end

    test "review notification email contains change details and approval links", %{
      conn: conn,
      school: school,
      address: address
    } do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Open delete modal and submit
      view |> element("button", "Schule löschen") |> render_click()

      view
      |> element("form[phx-submit=\"confirm_delete\"]")
      |> render_submit(%{
        "zip_code_confirmation" => address.zip_code,
        "deletion_reason" => "Test"
      })

      assert_redirect(view, "/wiki")

      [pending_change] = PendingChanges.list_pending()

      # Check the notification email describes the pending change
      assert_email_sent(fn email ->
        assert email.subject == "Wiki-Änderung zur Prüfung: Schule löschen: #{school.name}"

        # Change details
        assert email.html_body =~ "Wiki-Änderung zur Prüfung"
        assert email.html_body =~ "Änderungstyp:</strong> Schule löschen"
        assert email.html_body =~ "Schulname:</strong> #{school.name}"
        assert email.html_body =~ "Schul-ID:</strong> #{school.id}"
        assert email.html_body =~ "/wiki/schools/#{school.slug}"
        assert email.html_body =~ "Löschgrund:</strong> Test"

        # Approve/reject magic links
        assert email.html_body =~ "/wiki/approve/#{pending_change.approval_token}"
        assert email.html_body =~ "/wiki/reject/#{pending_change.rejection_token}"

        # Text part mirrors the details
        assert email.text_body =~ "Änderungstyp: Schule löschen"
        assert email.text_body =~ "Löschgrund: Test"
      end)
    end

    test "queues deletion for school without address and deletes it after approval", %{conn: conn} do
      # Create school without address
      {:ok, school} =
        %Location{
          name: "School Without Address",
          slug: "school-without-address-#{System.unique_integer([:positive])}",
          is_school: true
        }
        |> Repo.insert()

      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Open delete modal
      view |> element("button", "Schule löschen") |> render_click()

      # Submit with empty ZIP (since no address exists)
      assert view
             |> element("form[phx-submit=\"confirm_delete\"]")
             |> render_submit(%{
               "zip_code_confirmation" => "",
               "deletion_reason" => "No address test"
             })

      # The delete request is queued for review
      flash = assert_redirect(view, "/wiki")

      assert flash["info"] ==
               "Ihre Löschanfrage wurde zur Überprüfung eingereicht. Sie wird nach Genehmigung umgesetzt."

      # School still exists until the change is approved
      assert Locations.get_school_by_slug!(school.slug)

      [pending_change] = PendingChanges.list_pending()
      assert pending_change.change_type == "delete_school"
      assert pending_change.payload["deletion_reason"] == "No address test"

      # The review notification email was sent on submission
      assert_email_sent(subject: "Wiki-Änderung zur Prüfung: Schule löschen: #{school.name}")

      # Approving the change deletes the school
      {:ok, _result} = PendingChanges.approve_change!(pending_change)

      assert_raise Ecto.NoResultsError, fn ->
        Locations.get_school_by_slug!(school.slug)
      end
    end
  end
end
