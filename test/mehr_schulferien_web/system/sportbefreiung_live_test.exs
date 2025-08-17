defmodule MehrSchulferienWeb.SportbefreiungLiveSystemTest do
  use MehrSchulferienWeb.ConnCase

  import Phoenix.LiveViewTest
  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers
  import MehrSchulferienWeb.FormLiveTestHelpers

  describe "SportbefreiungLive" do
    setup [:create_school]

    test "loads the sportbefreiung page successfully", %{conn: conn, school: school} do
      {:ok, _view, html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      assert_common_page_elements(html, school.name)
      assert html =~ "Details zur Sportbefreiung"
    end

    test "displays form fields correctly", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      assert_sender_fields_present(view)
      assert_student_fields_present(view)

      # Sportbefreiung-specific fields
      assert has_element?(view, "input[name='form[duration_type]'][value='single_lesson']")
      assert has_element?(view, "input[name='form[duration_type]'][value='period']")
      assert has_element?(view, "#form_single_date")
      assert has_element?(view, "#form_start_date")
      assert has_element?(view, "#form_end_date")
      assert has_element?(view, "#form_detailed_reason")
      assert has_element?(view, "input[name='form[medical_certificate]']")
      assert has_element?(view, "button[type='submit']")
    end

    test "validates required fields", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      html = submit_form(view)

      assert html =~ "Bitte füllen Sie alle Pflichtfelder aus"
    end

    test "handles single lesson exemption", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      # Select single lesson and fill form
      fill_sender_fields(view)
      fill_student_fields(view)

      view
      |> element("form")
      |> render_change(%{
        form: %{
          duration_type: "single_lesson",
          single_date: ~D[2024-12-05],
          detailed_reason: "Verletzung am Fuß"
        }
      })

      html = submit_form(view)
      refute html =~ "Bitte füllen Sie alle Pflichtfelder aus"
    end

    test "handles period exemption", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      # Fill form with period selection
      fill_sender_fields(view)
      fill_student_fields(view)

      view
      |> element("form")
      |> render_change(%{
        form: %{
          duration_type: "period",
          start_date: ~D[2024-12-05],
          end_date: ~D[2024-12-19],
          detailed_reason: "Knieoperation",
          medical_certificate: true
        }
      })

      html = submit_form(view)
      refute html =~ "Bitte füllen Sie alle Pflichtfelder aus"
    end

    test "validates date order for period exemption", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      # Select period via form change
      view
      |> element("form")
      |> render_change(%{
        form: %{
          duration_type: "period"
        }
      })

      test_date_validation(view, :start_date, :end_date)
    end

    test "submits form with valid data for single lesson", %{conn: conn, school: school} do
      form_params = %{
        title: "Herr",
        first_name: "Max",
        last_name: "Mustermann",
        street: "Musterstraße 1",
        zip_code: "12345",
        city: "Musterstadt",
        name_of_student: "Maria Mustermann",
        class_name: "7a",
        duration_type: "single_lesson",
        single_date: ~D[2024-12-05],
        detailed_reason: "Verletzung",
        medical_certificate: false
      }

      test_pdf_generation(conn, "/briefe/#{school.slug}/sportbefreiung", school, form_params)
    end

    test "submits form with valid data for period", %{conn: conn, school: school} do
      form_params = %{
        title: "Frau",
        first_name: "Anna",
        last_name: "Schmidt",
        street: "Hauptstraße 10",
        zip_code: "54321",
        city: "Beispielstadt",
        name_of_student: "Tom Schmidt",
        class_name: "9b",
        duration_type: "period",
        start_date: ~D[2024-12-05],
        end_date: ~D[2024-12-19],
        detailed_reason: "Operation am Knie mit anschließender Rehabilitation",
        medical_certificate: true
      }

      test_pdf_generation(conn, "/briefe/#{school.slug}/sportbefreiung", school, form_params)
    end

    test "toggles between single lesson and period", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      # Start with single lesson
      html =
        view
        |> element("form")
        |> render_change(%{
          form: %{
            duration_type: "single_lesson"
          }
        })

      assert html =~ "form_single_date"

      # Switch to period
      html =
        view
        |> element("form")
        |> render_change(%{
          form: %{
            duration_type: "period"
          }
        })

      assert html =~ "form_start_date"
      assert html =~ "form_end_date"
    end

    test "pre-fills school address", %{conn: conn} do
      school_with_address = insert(:school_with_address)
      {:ok, _view, html} = live(conn, "/briefe/#{school_with_address.slug}/sportbefreiung")

      assert html =~ school_with_address.address.street
      assert html =~ school_with_address.address.zip_code
      assert html =~ school_with_address.address.city
    end

    test "shows proper error for invalid school slug", %{conn: conn} do
      assert_error_sent 404, fn ->
        live(conn, "/briefe/invalid-school-slug/sportbefreiung")
      end
    end
  end
end
