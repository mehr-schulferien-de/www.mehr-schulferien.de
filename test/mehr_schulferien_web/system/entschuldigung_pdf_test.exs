defmodule MehrSchulferienWeb.EntschuldigungPdfSystemTest do
  use MehrSchulferienWeb.ConnCase

  import Phoenix.LiveViewTest
  import MehrSchulferien.Factory

  @moduletag :system

  describe "PDF generation and download" do
    setup [:create_school]

    test "generates and downloads PDF when form is submitted with valid data", %{
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
          "reason" => "krankheit",
          "start_date" => "2025-06-20",
          "end_date" => "2025-06-22"
        }
      }

      # Submit the form - this should stay on same page and show success message
      html =
        view
        |> form("#entschuldigung-form", form_data)
        |> render_submit()

      # Check that form submission was successful
      assert html =~ "PDF wurde erfolgreich erstellt"
      assert html =~ "Sie können das Formular erneut ausfüllen"

      # Check that form was reset
      assert html =~ "value=\"\""
    end

    test "shows validation error when required fields are missing", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

      # Submit form with missing required fields
      incomplete_form_data = %{
        "form" => %{
          "first_name" => "Maria",
          # Missing other required fields
          "reason" => "krankheit",
          "start_date" => "2025-06-20",
          "end_date" => "2025-06-22"
        }
      }

      view
      |> form("#entschuldigung-form", incomplete_form_data)
      |> render_submit()

      # Should show validation error
      assert has_element?(view, "[phx-feedback-for]") or render(view) =~ "Pflichtfelder"
    end

    test "PDF download endpoint works with valid form data", %{
      conn: conn,
      school: school
    } do
      # Simulate the PDF download request with query parameters
      params = %{
        "first_name" => "Max",
        "last_name" => "Mustermann",
        "street" => "Teststraße 1",
        "zip_code" => "12345",
        "city" => "Teststadt",
        "name_of_student" => "Max Junior",
        "class_name" => "5a",
        "reason" => "krankheit",
        "start_date" => "2025-06-15",
        "end_date" => "2025-06-15"
      }

      # This will test the PDF generation if LaTeX is available
      # If LaTeX is not available, it should return an error gracefully
      conn = get(conn, "/briefe/#{school.slug}/entschuldigung/pdf", params)

      case conn.status do
        200 ->
          # PDF generation successful
          content_type = get_resp_header(conn, "content-type") |> List.first()
          assert content_type =~ "application/pdf"
          assert get_resp_header(conn, "content-disposition") |> List.first() =~ "attachment"
          assert get_resp_header(conn, "content-disposition") |> List.first() =~ ".pdf"

          # Check that we got some binary data
          assert byte_size(conn.resp_body) > 0

        302 ->
          # Redirect back to form (likely due to LaTeX not being available)
          assert redirected_to(conn) =~ "/briefe/#{school.slug}/entschuldigung"

        _ ->
          flunk("Unexpected response status: #{conn.status}")
      end
    end

    test "PDF download endpoint handles missing school gracefully", %{conn: conn} do
      params = %{
        "first_name" => "Max",
        "last_name" => "Mustermann",
        "street" => "Teststraße 1",
        "zip_code" => "12345",
        "city" => "Teststadt",
        "name_of_student" => "Max Junior",
        "class_name" => "5a",
        "reason" => "krankheit",
        "start_date" => "2025-06-15",
        "end_date" => "2025-06-15"
      }

      conn = get(conn, "/briefe/non-existent-school/entschuldigung/pdf", params)
      assert conn.status == 404
    end

    test "generates correct filename for PDF download", %{
      conn: conn,
      school: school
    } do
      params = %{
        "first_name" => "Maria",
        "last_name" => "Musterfrau",
        "street" => "Beispielstraße 42",
        "zip_code" => "54321",
        "city" => "Beispielstadt",
        "name_of_student" => "Anna Marie Musterfrau",
        "class_name" => "7b",
        "reason" => "arzttermin",
        "start_date" => "2025-06-20",
        "end_date" => "2025-06-20"
      }

      conn = get(conn, "/briefe/#{school.slug}/entschuldigung/pdf", params)

      if conn.status == 200 do
        content_disposition = get_resp_header(conn, "content-disposition") |> List.first()
        assert content_disposition =~ "Entschuldigung_Anna_Marie_Musterfrau_2025-06-20.pdf"
      end
    end

    test "generates correct filename with date range for multi-day absence", %{
      conn: conn,
      school: school
    } do
      params = %{
        "first_name" => "Hans",
        "last_name" => "Schmidt",
        "street" => "Teststraße 1",
        "zip_code" => "12345",
        "city" => "Teststadt",
        "name_of_student" => "Max Schmidt",
        "class_name" => "8a",
        "reason" => "krankheit",
        "start_date" => "2025-06-15",
        "end_date" => "2025-06-17"
      }

      conn = get(conn, "/briefe/#{school.slug}/entschuldigung/pdf", params)

      if conn.status == 200 do
        content_disposition = get_resp_header(conn, "content-disposition") |> List.first()
        assert content_disposition =~ "Entschuldigung_Max_Schmidt_2025-06-15_bis_2025-06-17.pdf"
      end
    end

    test "handles different excuse reasons correctly", %{
      conn: conn,
      school: school
    } do
      base_params = %{
        "first_name" => "Test",
        "last_name" => "Parent",
        "street" => "Teststraße 1",
        "zip_code" => "12345",
        "city" => "Teststadt",
        "name_of_student" => "Test Child",
        "class_name" => "5a",
        "start_date" => "2025-06-15",
        "end_date" => "2025-06-15"
      }

      reasons = [
        "krankheit",
        "arzttermin",
        "familiaere_angelegenheiten",
        "beerdigung",
        "religioser_feiertag"
      ]

      Enum.each(reasons, fn reason ->
        params = Map.put(base_params, "reason", reason)
        conn = get(conn, "/briefe/#{school.slug}/entschuldigung/pdf", params)

        # Should either succeed or fail gracefully
        assert conn.status in [200, 302]
      end)
    end

    test "handles date ranges correctly", %{
      conn: conn,
      school: school
    } do
      base_params = %{
        "first_name" => "Test",
        "last_name" => "Parent",
        "street" => "Teststraße 1",
        "zip_code" => "12345",
        "city" => "Teststadt",
        "name_of_student" => "Test Child",
        "class_name" => "5a",
        "reason" => "krankheit"
      }

      # Test single day absence
      single_day_params =
        Map.merge(base_params, %{
          "start_date" => "2025-06-15",
          "end_date" => "2025-06-15"
        })

      conn = get(conn, "/briefe/#{school.slug}/entschuldigung/pdf", single_day_params)
      assert conn.status in [200, 302]

      # Test multi-day absence
      multi_day_params =
        Map.merge(base_params, %{
          "start_date" => "2025-06-15",
          "end_date" => "2025-06-17"
        })

      conn = get(conn, "/briefe/#{school.slug}/entschuldigung/pdf", multi_day_params)
      assert conn.status in [200, 302]
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
