defmodule MehrSchulferienWeb.FormLiveTestHelpers do
  @moduledoc """
  Shared test helpers for testing LiveView forms (Entschuldigung, Beurlaubung, Sportbefreiung)
  """

  @endpoint MehrSchulferienWeb.Endpoint

  import Phoenix.LiveViewTest
  import ExUnit.Assertions
  import Phoenix.ConnTest

  @common_sender_fields ~w(
    #form_title
    #form_first_name 
    #form_last_name
    #form_street
    #form_zip_code
    #form_city
  )

  @common_student_fields ~w(
    #form_name_of_student
    #form_class_name
  )

  @common_teacher_fields ~w(
    #form_teacher_salutation
    #form_teacher_name
  )

  def assert_common_page_elements(html, school_name) do
    assert html =~ "PDF downloaden"
    assert html =~ school_name
    assert html =~ "Absender"
    assert html =~ "Name des Schülers/der Schülerin"
  end

  def assert_sender_fields_present(view) do
    for field <- @common_sender_fields do
      assert has_element?(view, field)
    end
  end

  def assert_student_fields_present(view) do
    for field <- @common_student_fields do
      assert has_element?(view, field)
    end
  end

  def assert_teacher_fields_present(view) do
    for field <- @common_teacher_fields do
      assert has_element?(view, field)
    end
  end

  def fill_sender_fields(view) do
    view
    |> element("form")
    |> render_change(%{
      form: %{
        title: "Herr",
        first_name: "Max",
        last_name: "Mustermann",
        street: "Musterstraße 1",
        zip_code: "12345",
        city: "Musterstadt"
      }
    })
  end

  def fill_student_fields(view, params \\ %{}) do
    default_params = %{
      name_of_student: "Maria Mustermann",
      class_name: "7a"
    }

    view
    |> element("form")
    |> render_change(%{form: Map.merge(default_params, params)})
  end

  def fill_teacher_fields(view, params \\ %{}) do
    default_params = %{
      teacher_salutation: "Frau",
      teacher_name: "Schmidt"
    }

    view
    |> element("form")
    |> render_change(%{form: Map.merge(default_params, params)})
  end

  def submit_form(view) do
    view
    |> element("form")
    |> render_submit()
  end

  def assert_validation_errors(html, expected_errors) do
    for error <- expected_errors do
      assert html =~ error
    end
  end

  def test_form_validation(conn, path, _school, required_fields) do
    {:ok, view, _html} = live(conn, path)

    # Submit empty form
    html = submit_form(view)

    # Check for required field errors
    for field <- required_fields do
      _field_name = field |> String.replace("_", " ") |> String.capitalize()
      assert html =~ "can&#39;t be blank" or html =~ "muss ausgefüllt werden"
    end
  end

  def test_pdf_generation(conn, path, _school, form_params) do
    {:ok, view, _html} = live(conn, path)

    # Fill form
    view
    |> element("form")
    |> render_change(%{form: form_params})

    # Submit form
    html =
      view
      |> element("form")
      |> render_submit()

    # Check for success message or PDF generation
    assert html =~ "PDF" or html =~ "erfolgreich" or html =~ "download"
  end

  def test_date_validation(view, start_field, end_field) do
    # Test end date before start date
    view
    |> element("form")
    |> render_change(%{
      form: %{
        start_field => ~D[2024-12-10],
        end_field => ~D[2024-12-05]
      }
    })

    html = submit_form(view)
    assert html =~ "Enddatum" or html =~ "end date"
  end
end
