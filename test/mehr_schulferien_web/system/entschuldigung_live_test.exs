defmodule MehrSchulferienWeb.EntschuldigungLiveSystemTest do
  use MehrSchulferienWeb.ConnCase

  import Phoenix.LiveViewTest
  import MehrSchulferien.Factory

  describe "EntschuldigungLive" do
    setup [:create_school]

    test "loads the entschuldigung page successfully", %{
      conn: conn,
      school: school
    } do
      {:ok, _view, html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

      # Check that the page loads without KeyError exceptions
      assert html =~ "Entschuldigung schreiben"
      assert html =~ school.name
      assert html =~ "Absender"
      assert html =~ "Name des Schülers/der Schülerin"
      assert html =~ "Entschuldigungsdetails"
    end

    test "displays form fields correctly", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

      # Check personal information fields
      assert has_element?(view, "#form_title")
      assert has_element?(view, "#form_first_name")
      assert has_element?(view, "#form_last_name")
      assert has_element?(view, "#form_street")
      assert has_element?(view, "#form_zip_code")
      assert has_element?(view, "#form_city")

      # Check student information fields
      assert has_element?(view, "#form_name_of_student")
      assert has_element?(view, "#form_class_name")
      assert has_element?(view, "#form_reason")
      assert has_element?(view, "#form_start_date")
      assert has_element?(view, "#form_end_date")

      # Check Klassenlehrer/in fields
      assert has_element?(view, "#form_teacher_salutation")
      assert has_element?(view, "#form_teacher_name")

      # Check submit button
      assert has_element?(view, "button[type='submit']")

      # Check school address is displayed
      html = render(view)
      assert html =~ "Max-von-Laue-Gymnasium"
      assert html =~ "Südallee 1"
      assert html =~ "56068 Koblenz"
    end

    test "validates form on change", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

      # Fill in some form data
      form_data = %{
        "form" => %{
          "first_name" => "Max",
          "last_name" => "Mustermann",
          "street" => "Musterstraße 1",
          "zip_code" => "12345",
          "city" => "Musterstadt",
          "name_of_student" => "Max Junior",
          "class_name" => "5a",
          "reason" => "krankheit",
          "start_date" => "2025-06-15"
        }
      }

      # Trigger form validation
      view |> form("#entschuldigung-form", form_data) |> render_change()

      # The form should update without errors
      # Check that some values are reflected in the form
      html = render(view)
      assert html =~ "value=\"Max\""
      assert html =~ "value=\"Mustermann\""
    end

    test "handles form submission", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

      # Fill in complete valid form data
      form_data = %{
        "form" => %{
          "title" => "Dr.",
          "first_name" => "Maria",
          "last_name" => "Musterfrau",
          "street" => "Beispielstraße 42",
          "zip_code" => "54321",
          "city" => "Beispielstadt",
          "name_of_student" => "Anna Musterfrau",
          "class_name" => "7b",
          "reason" => "arzttermin",
          "start_date" => "2025-06-20",
          "end_date" => "2025-06-20",
          "teacher_salutation" => "Herr",
          "teacher_name" => "Schulze"
        }
      }

      # Submit the form - should stay on same page and show success message
      html =
        view
        |> form("#entschuldigung-form", form_data)
        |> render_submit()

      # Check that form was successful and shows success message
      assert html =~ "PDF wurde erfolgreich erstellt"
      assert html =~ "Sie können das Formular erneut ausfüllen"

      # Check that form data is preserved - input fields should contain the submitted values
      assert html =~ "value=\"Maria\""
      assert html =~ "value=\"Musterfrau\""
      assert html =~ "value=\"Dr.\""
      assert html =~ "value=\"Beispielstraße 42\""
      assert html =~ "value=\"54321\""
      assert html =~ "value=\"Beispielstadt\""
      assert html =~ "value=\"Anna Musterfrau\""
      assert html =~ "value=\"7b\""
      # teacher salutation and name should be preserved
      assert html =~ "Herr"
      assert html =~ "value=\"Schulze\""
      # selected reason should be preserved
      assert html =~ "arzttermin"
    end

    test "displays both date fields always", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

      # Both date fields should always be present
      assert has_element?(view, "#form_start_date")
      assert has_element?(view, "#form_end_date")

      # Check that labels are correct
      html = render(view)
      assert html =~ "Startdatum"
      assert html =~ "Enddatum"

      # Test form validation with both dates
      form_data = %{
        "form" => %{
          "start_date" => "2025-06-15",
          "end_date" => "2025-06-17"
        }
      }

      view |> form("#entschuldigung-form", form_data) |> render_change()

      # Both fields should still be present and contain the values
      assert has_element?(view, "#form_start_date")
      assert has_element?(view, "#form_end_date")

      html = render(view)
      assert html =~ "2025-06-15"
      assert html =~ "2025-06-17"
    end

    test "displays reason dropdown options (if available)", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

      html = render(view)

      # Check that the reason dropdown exists with expected options
      assert html =~ "name=\"form[reason]\""
      assert html =~ "Krankheit"
      assert html =~ "Arzttermin"
    end

    test "handles date validation", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

      # Test with valid date
      form_data = %{
        "form" => %{
          "start_date" => "2025-12-25"
        }
      }

      view |> form("#entschuldigung-form", form_data) |> render_change()

      # The form should handle date input without errors
      html = render(view)
      assert html =~ "2025-12-25"
    end

    test "preserves form data across validation events", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

      # Fill in initial data
      initial_data = %{
        "form" => %{
          "first_name" => "TestName",
          "last_name" => "TestLastName"
        }
      }

      view |> form("#entschuldigung-form", initial_data) |> render_change()

      # Add more data
      additional_data = %{
        "form" => %{
          "first_name" => "TestName",
          "last_name" => "TestLastName",
          "city" => "TestCity"
        }
      }

      view |> form("#entschuldigung-form", additional_data) |> render_change()

      # Check that both pieces of data are preserved
      html = render(view)
      assert html =~ "TestName"
      assert html =~ "TestLastName"
      assert html =~ "TestCity"
    end

    test "displays school information correctly", %{
      conn: conn,
      school: school
    } do
      {:ok, _view, html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

      # Check that school information is displayed
      assert html =~ school.name
      assert html =~ "Schule"
    end

    test "handles missing school gracefully", %{conn: conn} do
      # Test with non-existent school slug
      assert_raise Ecto.NoResultsError, fn ->
        live(conn, "/briefe/non-existent-school/entschuldigung")
      end
    end

    test "navigation dropdowns are collapsed by default", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

      # Check that navigation dropdown elements have x-cloak attribute
      # This ensures Alpine.js will hide them before initialization
      html = render(view)
      assert html =~ "x-cloak"

      # The dropdowns should not be visible initially (due to x-cloak and Alpine.js)
      refute has_element?(view, "[x-show='desktopDropdown2025Open'][style*='display: block']")
      refute has_element?(view, "[x-show='desktopDropdown2026Open'][style*='display: block']")
      refute has_element?(view, "[x-show='brueckenDropdown2025Open'][style*='display: block']")
      refute has_element?(view, "[x-show='brueckenDropdown2026Open'][style*='display: block']")
    end

    test "can reuse form after PDF generation", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

      # Fill in initial form data
      initial_form_data = %{
        "form" => %{
          "title" => "Dr.",
          "first_name" => "Maria",
          "last_name" => "Musterfrau",
          "street" => "Beispielstraße 42",
          "zip_code" => "54321",
          "city" => "Beispielstadt",
          "name_of_student" => "Anna Musterfrau",
          "class_name" => "7b",
          "reason" => "krankheit",
          "start_date" => "2025-06-20",
          "end_date" => "2025-06-20",
          "teacher_salutation" => "Herr",
          "teacher_name" => "Schulze"
        }
      }

      # Submit the form - should stay on same page and show success message
      html = view |> form("#entschuldigung-form", initial_form_data) |> render_submit()

      # Verify success message and form data is preserved
      assert html =~ "PDF wurde erfolgreich erstellt"
      assert html =~ "Sie können das Formular erneut ausfüllen"

      # Verify form data is preserved and ready for reuse/modification
      assert html =~ "Entschuldigung schreiben"
      assert html =~ "value=\"Maria\""
      assert html =~ "value=\"Musterfrau\""
      assert html =~ "value=\"Dr.\""
      assert html =~ "value=\"Anna Musterfrau\""
      assert html =~ "value=\"7b\""
      assert html =~ "PDF downloaden"

      # Fill in new form data with different dates
      new_form_data = %{
        "form" => %{
          "title" => "Prof.",
          "first_name" => "Hans",
          "last_name" => "Müller",
          "street" => "Neue Straße 1",
          "zip_code" => "12345",
          "city" => "Berlin",
          "name_of_student" => "Max Müller",
          "class_name" => "8a",
          "reason" => "arzttermin",
          "start_date" => "2025-06-25",
          "end_date" => "2025-06-25",
          "teacher_salutation" => "Frau",
          "teacher_name" => "Schmidt"
        }
      }

      # Submit the form again - should work and show success message again
      html = view |> form("#entschuldigung-form", new_form_data) |> render_submit()

      # Verify second submission also works
      assert html =~ "PDF wurde erfolgreich erstellt"
      assert html =~ "Sie können das Formular erneut ausfüllen"

      # Verify form data from second submission is preserved
      assert html =~ "value=\"Hans\""
      assert html =~ "value=\"Müller\""
      assert html =~ "value=\"Prof.\""
      assert html =~ "value=\"Max Müller\""
      assert html =~ "value=\"8a\""
    end
  end

  defp create_school(_) do
    # Create the location hierarchy needed for a school
    country = insert(:country, %{slug: "d", name: "Deutschland"})

    federal_state =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "rheinland-pfalz",
        name: "Rheinland-Pfalz"
      })

    county =
      insert(:county, %{
        parent_location_id: federal_state.id,
        slug: "koblenz",
        name: "Koblenz"
      })

    city =
      insert(:city, %{
        parent_location_id: county.id,
        slug: "koblenz",
        name: "Koblenz"
      })

    school =
      insert(:school, %{
        parent_location_id: city.id,
        slug: "56068-max-von-laue-gymnasium",
        name: "Max-von-Laue-Gymnasium"
      })

    # Create an address for the school
    insert(:address, %{
      school_location_id: school.id,
      street: "Südallee 1",
      zip_code: "56068",
      city: "Koblenz",
      email_address: "schulleitung@mvlg.de",
      phone_number: "+49 261 914830",
      homepage_url: "https://mvlg.de"
    })

    {:ok,
     %{school: school, country: country, federal_state: federal_state, county: county, city: city}}
  end
end
