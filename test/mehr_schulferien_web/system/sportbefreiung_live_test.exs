defmodule MehrSchulferienWeb.SportbefreiungLiveSystemTest do
  use MehrSchulferienWeb.ConnCase

  import Phoenix.LiveViewTest
  import MehrSchulferien.Factory

  describe "SportbefreiungLive" do
    setup [:create_school]

    test "loads the sportbefreiung page successfully", %{
      conn: conn,
      school: school
    } do
      {:ok, _view, html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      # Check that the page loads without KeyError exceptions
      assert html =~ "PDF downloaden"
      assert html =~ school.name
      assert html =~ "Absender"
      assert html =~ "Name des Schülers/der Schülerin"
      assert html =~ "Details zur Sportbefreiung"
    end

    test "displays form fields correctly", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

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

      # Check sport-specific fields
      assert has_element?(view, "input[name='form[duration_type]'][value='single_lesson']")
      assert has_element?(view, "input[name='form[duration_type]'][value='period']")
      assert has_element?(view, "#form_single_date")
      assert has_element?(view, "#form_start_date")
      assert has_element?(view, "#form_end_date")
      assert has_element?(view, "#form_detailed_reason")
      assert has_element?(view, "input[name='form[medical_certificate]']")

      # Check Sportlehrer/in fields
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
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

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
          "single_date" => "2025-06-15",
          "detailed_reason" => "Verletzung am Fuß nach Sportunfall"
        }
      }

      # Trigger form validation
      view |> form("#sportbefreiung-form", form_data) |> render_change()

      # The form should update without errors
      # Check that some values are reflected in the form
      html = render(view)
      assert html =~ "value=\"Max\""
      assert html =~ "value=\"Mustermann\""
    end

    test "handles form submission for single lesson", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      # Fill in complete valid form data for single lesson
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
          "duration_type" => "single_lesson",
          "single_date" => "2025-06-20",
          "teacher_salutation" => "Herr",
          "teacher_name" => "Schmidt",
          "detailed_reason" =>
            "Aufgrund einer Verletzung am Knöchel kann meine Tochter heute nicht am Sportunterricht teilnehmen.",
          "medical_certificate" => "true"
        }
      }

      # Submit the form - should stay on same page and show success message
      html =
        view
        |> form("#sportbefreiung-form", form_data)
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
      assert html =~ "Aufgrund einer Verletzung"
      # teacher salutation and name should be preserved
      assert html =~ "Herr"
      assert html =~ "value=\"Schmidt\""
    end

    test "handles form submission for period", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      # First select period duration type via form change
      form_data = %{
        "form" => %{
          "duration_type" => "period"
        }
      }

      view |> form("#sportbefreiung-form", form_data) |> render_change()

      # Fill in complete valid form data for period
      form_data = %{
        "form" => %{
          "title" => "",
          "first_name" => "Thomas",
          "last_name" => "Müller",
          "street" => "Hauptstraße 15",
          "zip_code" => "67890",
          "city" => "Teststadt",
          "name_of_student" => "Tim Müller",
          "class_name" => "9a",
          "duration_type" => "period",
          "start_date" => "2025-06-20",
          "end_date" => "2025-07-10",
          "teacher_salutation" => "Frau",
          "teacher_name" => "Weber",
          "detailed_reason" =>
            "Nach einer Operation am Knie ist eine längere Schonung erforderlich. Ein ärztliches Attest liegt bei.",
          "medical_certificate" => "true"
        }
      }

      # Submit the form
      html =
        view
        |> form("#sportbefreiung-form", form_data)
        |> render_submit()

      # Check success
      assert html =~ "PDF wurde erfolgreich erstellt"

      # Check data preservation
      assert html =~ "value=\"Thomas\""
      assert html =~ "value=\"Müller\""
      assert html =~ "value=\"Tim Müller\""
      assert html =~ "längere Schonung erforderlich"
    end

    test "shows validation errors for missing required fields", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      # Submit with incomplete data
      form_data = %{
        "form" => %{
          "first_name" => "Test",
          "last_name" => "",
          "zip_code" => "",
          "city" => "Stadt",
          "name_of_student" => "",
          "class_name" => "5a",
          "detailed_reason" => ""
        }
      }

      html =
        view
        |> form("#sportbefreiung-form", form_data)
        |> render_submit()

      # Should show error message
      assert html =~ "Bitte füllen Sie alle Pflichtfelder aus"
      assert html =~ "Nachname"
      assert html =~ "PLZ"
      assert html =~ "Name des Schülers"
      assert html =~ "Begründung"
    end

    test "duration type switching shows/hides appropriate fields", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      # Initially single_lesson should be selected
      html = render(view)
      assert html =~ "checked=\"checked\""
      assert html =~ "value=\"single_lesson\""

      # Single date field should be visible, period fields hidden
      assert html =~ ~s|id="single_date_field"|
      assert html =~ ~s|id="period_fields" style="display: none;"|

      # Change duration type to period via form change
      form_data = %{
        "form" => %{
          "duration_type" => "period"
        }
      }

      view |> form("#sportbefreiung-form", form_data) |> render_change()

      # Validate that period is now selected
      form_data = %{
        "form" => %{
          "duration_type" => "period"
        }
      }

      html = view |> form("#sportbefreiung-form", form_data) |> render_change()

      # Now period fields should be visible, single date hidden
      assert html =~ ~s|id="single_date_field" style="display: none;"|
      assert html =~ ~s|id="period_fields"|
      refute html =~ ~s|id="period_fields" style="display: none;"|
    end

    test "medical certificate checkbox works correctly", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      # Check the checkbox
      form_data = %{
        "form" => %{
          "medical_certificate" => "true"
        }
      }

      html = view |> form("#sportbefreiung-form", form_data) |> render_change()

      # Should show checked
      assert html =~ ~s|name="form[medical_certificate]" value="true" checked="checked"|
    end

    test "displays language switcher", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      # Check that language switcher component is present
      assert render(view) =~ "language-switcher"
    end

    test "breadcrumb navigation is correct", %{
      conn: conn,
      school: school
    } do
      {:ok, _view, html} = live(conn, "/briefe/#{school.slug}/sportbefreiung")

      # Check breadcrumb structure - school name and current page should be visible
      assert html =~ school.name
      # This is the link text for documents index
      assert html =~ "Formulare"
      assert html =~ "Sportbefreiung"
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
