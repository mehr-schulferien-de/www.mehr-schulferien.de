defmodule MehrSchulferienWeb.BeurlaubungLiveSystemTest do
  use MehrSchulferienWeb.ConnCase

  import Phoenix.LiveViewTest
  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers
  import MehrSchulferienWeb.FormLiveTestHelpers

  describe "BeurlaubungLive" do
    setup [:create_school]

    test "loads the beurlaubung page successfully", %{conn: conn, school: school} do
      {:ok, _view, html} = live(conn, "/briefe/#{school.slug}/beurlaubung")

      assert_common_page_elements(html, school.name)
      assert html =~ "Beurlaubungsdetails"
    end

    test "displays form fields correctly", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/beurlaubung")

      assert_sender_fields_present(view)
      assert_student_fields_present(view)
      assert_teacher_fields_present(view)

      # Beurlaubung-specific fields
      assert has_element?(view, "#form_start_date")
      assert has_element?(view, "#form_end_date")
      assert has_element?(view, "#form_detailed_reason")
      assert has_element?(view, "button[type='submit']")
    end

    test "validates required fields", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/beurlaubung")

      html = submit_form(view)

      assert html =~ "Bitte füllen Sie alle Pflichtfelder aus"
    end

    test "submits form with valid data", %{conn: conn, school: school} do
      form_params = %{
        title: "Herr",
        first_name: "Max",
        last_name: "Mustermann",
        street: "Musterstraße 1",
        zip_code: "12345",
        city: "Musterstadt",
        name_of_student: "Maria Mustermann",
        class_name: "7a",
        detailed_reason: "Familiäre Feier im Ausland",
        start_date: ~D[2024-12-05],
        end_date: ~D[2024-12-06],
        teacher_salutation: "Frau",
        teacher_name: "Schmidt"
      }

      test_pdf_generation(conn, "/briefe/#{school.slug}/beurlaubung", school, form_params)
    end

    test "validates date order", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/beurlaubung")

      test_date_validation(view, :start_date, :end_date)
    end

    test "requires detailed reason", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/beurlaubung")

      # Fill all fields except detailed_reason
      fill_sender_fields(view)
      fill_student_fields(view)
      fill_teacher_fields(view)

      view
      |> element("form")
      |> render_change(%{
        form: %{
          start_date: ~D[2024-12-05],
          end_date: ~D[2024-12-06]
        }
      })

      html = submit_form(view)
      assert html =~ "Bitte füllen Sie alle Pflichtfelder aus"
    end

    test "handles multi-day leave request", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/beurlaubung")

      # Set different start and end dates
      view
      |> element("form")
      |> render_change(%{
        form: %{
          start_date: ~D[2024-12-05],
          end_date: ~D[2024-12-10],
          detailed_reason: "Familienurlaub"
        }
      })

      # Fill other required fields
      fill_sender_fields(view)
      fill_student_fields(view)
      fill_teacher_fields(view)

      html = submit_form(view)
      refute html =~ "Enddatum muss nach dem Startdatum liegen"
    end

    test "pre-fills school address", %{conn: conn} do
      school_with_address = insert(:school_with_address)
      {:ok, _view, html} = live(conn, "/briefe/#{school_with_address.slug}/beurlaubung")

      assert html =~ school_with_address.address.street
      assert html =~ school_with_address.address.zip_code
      assert html =~ school_with_address.address.city
    end

    test "shows proper error for invalid school slug", %{conn: conn} do
      assert_error_sent 404, fn ->
        live(conn, "/briefe/invalid-school-slug/beurlaubung")
      end
    end
  end
end
