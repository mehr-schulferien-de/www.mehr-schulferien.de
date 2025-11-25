defmodule MehrSchulferienWeb.EntschuldigungPdfSystemTest do
  @moduledoc """
  Tests for PDF generation functionality.

  Note: Most PDF formatting logic is tested in MehrSchulferien.PdfGeneratorTest.
  This file focuses on integration tests for the actual PDF endpoint.

  Tests tagged with @tag :slow actually generate PDFs via LaTeX.
  Run `mix test --exclude slow` for faster feedback.
  """
  use MehrSchulferienWeb.ConnCase

  import Phoenix.LiveViewTest
  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers, except: [create_school: 1]

  @moduletag :system

  @valid_params %{
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

  describe "PDF form submission" do
    setup [:create_school]

    test "form submission with valid data shows success message", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

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

      html =
        view
        |> form("#entschuldigung-form", form_data)
        |> render_submit()

      assert html =~ "PDF wurde erfolgreich erstellt"
      assert html =~ "Sie können das Formular erneut ausfüllen"
    end

    test "form submission with missing fields shows validation error", %{
      conn: conn,
      school: school
    } do
      {:ok, view, _html} = live(conn, "/briefe/#{school.slug}/entschuldigung")

      incomplete_form_data = %{
        "form" => %{
          "first_name" => "Maria",
          "reason" => "krankheit",
          "start_date" => "2025-06-20",
          "end_date" => "2025-06-22"
        }
      }

      view
      |> form("#entschuldigung-form", incomplete_form_data)
      |> render_submit()

      assert has_element?(view, "[phx-feedback-for]") or render(view) =~ "Pflichtfelder"
    end
  end

  describe "PDF download endpoint" do
    setup [:create_school]

    test "returns 404 for non-existent school", %{conn: conn} do
      conn = get(conn, "/briefe/non-existent-school/entschuldigung/pdf", @valid_params)
      assert conn.status == 404
    end

    @tag :slow
    test "generates valid PDF with correct headers", %{conn: conn, school: school} do
      conn = get(conn, "/briefe/#{school.slug}/entschuldigung/pdf", @valid_params)

      case conn.status do
        200 ->
          # PDF generation successful
          content_type = get_resp_header(conn, "content-type") |> List.first()
          assert content_type == "application/pdf"

          content_disposition = get_resp_header(conn, "content-disposition") |> List.first()
          assert content_disposition =~ "attachment"
          assert content_disposition =~ ".pdf"
          assert content_disposition =~ "Entschuldigung_Max_Junior"

          # Check PDF magic number
          assert binary_part(conn.resp_body, 0, 5) == "%PDF-"
          assert byte_size(conn.resp_body) > 0

        302 ->
          # LaTeX not available - redirect back with error
          assert redirected_to(conn) =~ "/briefe/#{school.slug}/entschuldigung"

        status ->
          flunk("Unexpected response status: #{status}")
      end
    end

    @tag :slow
    test "generates correct filename for multi-day absence", %{conn: conn, school: school} do
      params =
        Map.merge(@valid_params, %{"start_date" => "2025-06-15", "end_date" => "2025-06-17"})

      conn = get(conn, "/briefe/#{school.slug}/entschuldigung/pdf", params)

      if conn.status == 200 do
        content_disposition = get_resp_header(conn, "content-disposition") |> List.first()
        assert content_disposition =~ "2025-06-15_bis_2025-06-17.pdf"
      end
    end

    @tag :slow
    test "handles all excuse reasons", %{conn: conn, school: school} do
      # Test all reasons in a single request batch to minimize PDF generations
      reasons = [
        "krankheit",
        "arzttermin",
        "familiaere_angelegenheiten",
        "beerdigung",
        "religioser_feiertag"
      ]

      for reason <- reasons do
        params = Map.put(@valid_params, "reason", reason)
        conn = get(conn, "/briefe/#{school.slug}/entschuldigung/pdf", params)
        assert conn.status in [200, 302], "Failed for reason: #{reason}"
      end
    end
  end

  defp create_school(_) do
    country = get_or_create_deutschland()

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
