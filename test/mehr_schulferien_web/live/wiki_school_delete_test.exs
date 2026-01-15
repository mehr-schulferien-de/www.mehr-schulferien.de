defmodule MehrSchulferienWeb.WikiSchoolDeleteTest do
  use MehrSchulferienWeb.ConnCase

  # WIKI MAINTENANCE MODE: Tests skipped while wiki is disabled
  # To re-enable: remove this line and uncomment wiki routes in router.ex
  @moduletag :skip

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias MehrSchulferien.{Locations, Repo}
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Maps.Address

  describe "school deletion" do
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

    test "successfully deletes school with correct ZIP code", %{
      conn: conn,
      school: school,
      address: address,
      city: city
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

      # Should redirect
      assert_redirected(view, ~p"/ferien/d/stadt/#{city.slug}")

      # School should be deleted
      assert_raise Ecto.NoResultsError, fn ->
        Locations.get_school_by_slug!(school.slug)
      end

      # Check backup was created
      deleted_school = Repo.get_by(Locations.DeletedSchool, original_id: school.id)
      assert deleted_school
      assert deleted_school.name == school.name
      assert deleted_school.slug == school.slug
      assert deleted_school.deletion_reason == "School closed permanently"

      # Wait for async email
      Process.sleep(100)

      # Check email was sent
      assert_email_sent(
        subject: "Schule gelöscht: #{school.name}",
        to: {"Stefan Wintermeyer", "sw@wintermeyer-consulting.de"}
      )
    end

    test "includes deletion reason in email", %{conn: conn, school: school, address: address} do
      {:ok, view, _html} = live(conn, ~p"/wiki/schools/#{school.slug}/edit")

      # Open delete modal and submit
      view |> element("button", "Schule löschen") |> render_click()

      view
      |> element("form[phx-submit=\"confirm_delete\"]")
      |> render_submit(%{
        "zip_code_confirmation" => address.zip_code,
        "deletion_reason" => "Duplicate entry - merged with another school"
      })

      # Wait for async email
      Process.sleep(100)

      # Check email contains deletion reason
      assert_email_sent(fn email ->
        assert email.html_body =~ "Löschgrund:"
        assert email.html_body =~ "Duplicate entry - merged with another school"
        assert email.text_body =~ "Löschgrund: Duplicate entry - merged with another school"
      end)
    end

    test "email contains all school and address data", %{
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

      # Wait a bit for async email to be sent
      Process.sleep(100)

      # Check email contains all data
      assert_email_sent(fn email ->
        # School data
        assert email.html_body =~ school.name
        assert email.html_body =~ school.slug
        assert email.html_body =~ "ID:</strong> #{school.id}"

        # Address data
        assert email.html_body =~ address.street
        assert email.html_body =~ address.zip_code
        assert email.html_body =~ address.city
        assert email.html_body =~ address.email_address
        assert email.html_body =~ address.phone_number
        assert email.html_body =~ address.homepage_url

        # SQL recovery commands
        assert email.html_body =~ "SQL für Wiederherstellung"
        assert email.html_body =~ "INSERT INTO locations"
        assert email.html_body =~ "deleted_schools WHERE original_id = #{school.id}"
      end)
    end

    test "deletes school without address", %{conn: conn} do
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

      # Should redirect
      assert_redirected(view, ~p"/ferien/d")

      # School should be deleted
      assert_raise Ecto.NoResultsError, fn ->
        Locations.get_school_by_slug!(school.slug)
      end

      # Wait for async email
      Process.sleep(100)

      # Check email was sent
      assert_email_sent(fn email ->
        assert email.html_body =~ "Keine Adressdaten vorhanden"
      end)
    end
  end
end
