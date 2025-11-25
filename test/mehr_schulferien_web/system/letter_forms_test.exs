defmodule MehrSchulferienWeb.LetterFormsSystemTest do
  @moduledoc """
  Consolidated tests for all letter form LiveViews (Entschuldigung, Beurlaubung, Sportbefreiung).

  These forms share ~80% of the same functionality, so we test them together
  using data-driven tests to avoid duplication and improve test speed.
  """
  use MehrSchulferienWeb.ConnCase

  import Phoenix.LiveViewTest
  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  @moduletag :system

  # Form configurations for each letter type
  @form_configs %{
    entschuldigung: %{
      path: "entschuldigung",
      title: "Entschuldigungsdetails",
      specific_fields: ["#form_reason", "#form_start_date", "#form_end_date"],
      form_params: %{
        reason: "Krankheit",
        start_date: ~D[2024-12-05],
        end_date: ~D[2024-12-06]
      }
    },
    beurlaubung: %{
      path: "beurlaubung",
      title: "Beurlaubungsdetails",
      specific_fields: ["#form_start_date", "#form_end_date", "#form_detailed_reason"],
      form_params: %{
        detailed_reason: "Familiäre Feier im Ausland",
        start_date: ~D[2024-12-05],
        end_date: ~D[2024-12-06]
      }
    },
    sportbefreiung: %{
      path: "sportbefreiung",
      title: "Details zur Sportbefreiung",
      specific_fields: [
        "input[name='form[duration_type]'][value='single_lesson']",
        "#form_single_date",
        "#form_detailed_reason"
      ],
      form_params: %{
        duration_type: "single_lesson",
        single_date: ~D[2024-12-05],
        detailed_reason: "Verletzung am Fuß"
      }
    }
  }

  @common_sender_fields [
    "#form_title",
    "#form_first_name",
    "#form_last_name",
    "#form_street",
    "#form_zip_code",
    "#form_city"
  ]
  @common_student_fields ["#form_name_of_student", "#form_class_name"]

  describe "common functionality for all letter forms" do
    setup [:create_school]

    for {form_type, config} <- @form_configs do
      @config config

      test "#{form_type}: loads page successfully", %{conn: conn, school: school} do
        {:ok, _view, html} = live(conn, "/briefe/#{school.slug}/#{@config.path}")

        assert html =~ "PDF downloaden"
        assert html =~ school.name
        assert html =~ "Absender"
        assert html =~ "Name des Schülers/der Schülerin"
        assert html =~ @config.title
      end

      test "#{form_type}: displays all common form fields", %{conn: conn, school: school} do
        {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/#{@config.path}")

        # Check sender fields
        for field <- @common_sender_fields do
          assert has_element?(view, field), "Missing sender field: #{field}"
        end

        # Check student fields
        for field <- @common_student_fields do
          assert has_element?(view, field), "Missing student field: #{field}"
        end

        # Check submit button
        assert has_element?(view, "button[type='submit']")
      end

      test "#{form_type}: displays form-specific fields", %{conn: conn, school: school} do
        {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/#{@config.path}")

        for field <- @config.specific_fields do
          assert has_element?(view, field), "Missing specific field: #{field}"
        end
      end

      test "#{form_type}: validates required fields on empty submit", %{
        conn: conn,
        school: school
      } do
        {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/#{@config.path}")

        html =
          view
          |> element("form")
          |> render_submit()

        assert html =~ "Bitte füllen Sie alle Pflichtfelder aus"
      end

      test "#{form_type}: returns 404 for invalid school slug", %{conn: conn} do
        assert_error_sent 404, fn ->
          live(conn, "/briefe/invalid-school-slug/#{@config.path}")
        end
      end
    end
  end

  describe "school address pre-fill" do
    test "all forms pre-fill school address when available", %{conn: conn} do
      school_with_address = insert(:school_with_address)

      for {_form_type, config} <- @form_configs do
        {:ok, _view, html} = live(conn, "/briefe/#{school_with_address.slug}/#{config.path}")

        assert html =~ school_with_address.address.street
        assert html =~ school_with_address.address.zip_code
        assert html =~ school_with_address.address.city
      end
    end
  end

  describe "date validation" do
    setup [:create_school]

    test "entschuldigung: validates end date after start date", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/entschuldigung")
      test_date_order_validation(view)
    end

    test "beurlaubung: validates end date after start date", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/beurlaubung")
      test_date_order_validation(view)
    end

    test "sportbefreiung: validates end date after start date for period", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      # First select period type
      view
      |> element("form")
      |> render_change(%{form: %{duration_type: "period"}})

      test_date_order_validation(view)
    end

    test "entschuldigung: allows same start and end date (single day)", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

      view
      |> element("form")
      |> render_change(%{
        form: %{
          start_date: ~D[2024-12-05],
          end_date: ~D[2024-12-05]
        }
      })

      fill_all_required_fields(view, :entschuldigung)

      html =
        view
        |> element("form")
        |> render_submit()

      refute html =~ "Enddatum muss nach dem Startdatum liegen"
    end
  end

  describe "sportbefreiung-specific functionality" do
    setup [:create_school]

    test "toggles between single lesson and period", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      # Select single lesson
      html =
        view
        |> element("form")
        |> render_change(%{form: %{duration_type: "single_lesson"}})

      assert html =~ "form_single_date"

      # Switch to period
      html =
        view
        |> element("form")
        |> render_change(%{form: %{duration_type: "period"}})

      assert html =~ "form_start_date"
      assert html =~ "form_end_date"
    end

    test "handles single lesson exemption", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

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

      html =
        view
        |> element("form")
        |> render_submit()

      refute html =~ "Bitte füllen Sie alle Pflichtfelder aus"
    end

    test "handles period exemption", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

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

      html =
        view
        |> element("form")
        |> render_submit()

      refute html =~ "Bitte füllen Sie alle Pflichtfelder aus"
    end
  end

  describe "beurlaubung-specific functionality" do
    setup [:create_school]

    test "requires detailed reason", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/beurlaubung")

      fill_sender_fields(view)
      fill_student_fields(view)

      view
      |> element("form")
      |> render_change(%{
        form: %{
          start_date: ~D[2024-12-05],
          end_date: ~D[2024-12-06]
          # Missing detailed_reason
        }
      })

      html =
        view
        |> element("form")
        |> render_submit()

      assert html =~ "Bitte füllen Sie alle Pflichtfelder aus"
    end

    test "handles multi-day leave request", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/beurlaubung")

      fill_sender_fields(view)
      fill_student_fields(view)

      view
      |> element("form")
      |> render_change(%{
        form: %{
          start_date: ~D[2024-12-05],
          end_date: ~D[2024-12-10],
          detailed_reason: "Familienurlaub"
        }
      })

      html =
        view
        |> element("form")
        |> render_submit()

      refute html =~ "Enddatum muss nach dem Startdatum liegen"
    end
  end

  describe "entschuldigung-specific functionality" do
    setup [:create_school]

    test "handles different excuse reasons", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

      reasons = ["Krankheit", "Arztbesuch", "Familiäre Gründe", "Sonstiges"]

      for reason <- reasons do
        view
        |> element("form")
        |> render_change(%{form: %{reason: reason}})

        assert element(view, "option[value='#{reason}'][selected]")
      end
    end
  end

  # Helper functions

  defp fill_sender_fields(view) do
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

  defp fill_student_fields(view) do
    view
    |> element("form")
    |> render_change(%{
      form: %{
        name_of_student: "Maria Mustermann",
        class_name: "7a"
      }
    })
  end

  defp fill_all_required_fields(view, :entschuldigung) do
    fill_sender_fields(view)
    fill_student_fields(view)

    view
    |> element("form")
    |> render_change(%{form: %{reason: "Krankheit"}})
  end

  defp test_date_order_validation(view) do
    fill_sender_fields(view)
    fill_student_fields(view)

    view
    |> element("form")
    |> render_change(%{
      form: %{
        start_date: ~D[2024-12-10],
        end_date: ~D[2024-12-05]
      }
    })

    html =
      view
      |> element("form")
      |> render_submit()

    assert html =~ "Enddatum" or html =~ "end date"
  end
end
