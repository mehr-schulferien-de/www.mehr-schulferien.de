defmodule MehrSchulferienWeb.Api.V21.DocumentControllerTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  @moduletag :capture_log

  setup %{conn: conn} do
    # Create location hierarchy
    country = get_or_create_deutschland()

    federal_state =
      insert(:federal_state, %{
        name: "Bayern",
        slug: "bayern",
        parent_location_id: country.id
      })

    county =
      insert(:county, %{
        name: "München",
        slug: "muenchen-landkreis",
        parent_location_id: federal_state.id
      })

    city =
      insert(:city, %{
        name: "München",
        slug: "muenchen",
        parent_location_id: county.id
      })

    # Create school with address
    school =
      insert(:school, %{
        name: "Gymnasium München Nord",
        slug: "gymnasium-muenchen-nord",
        parent_location_id: city.id
      })

    address =
      insert(:address, %{
        school_location_id: school.id,
        street: "Musterstraße 1",
        zip_code: "80333",
        city: "München",
        phone_number: "089 123456",
        email_address: "info@gymnasium.de"
      })

    conn = put_req_header(conn, "accept", "application/json")

    {:ok, conn: conn, school: school, address: address}
  end

  describe "POST /api/v2.1/schools/:slug/documents - Entschuldigung" do
    test "creates PDF with valid data", %{conn: conn, school: school} do
      params = %{
        "type" => "entschuldigung",
        "first_name" => "Max",
        "last_name" => "Mustermann",
        "zip_code" => "80333",
        "city" => "München",
        "name_of_student" => "Anna Mustermann",
        "class_name" => "5a",
        "reason" => "krankheit",
        "start_date" => "2025-01-15",
        "end_date" => "2025-01-17"
      }

      conn = post(conn, ~p"/api/v2.1/schools/#{school.slug}/documents", params)

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/pdf"]

      assert get_resp_header(conn, "content-disposition") == [
               "attachment; filename=Entschuldigung_Anna_Mustermann_2025-01-15_bis_2025-01-17.pdf"
             ]

      # Verify it's a PDF
      assert String.starts_with?(conn.resp_body, "%PDF")
    end

    test "creates PDF with optional fields", %{conn: conn, school: school} do
      params = %{
        "type" => "entschuldigung",
        "first_name" => "Dr. Max",
        "last_name" => "Mustermann",
        "title" => "Dr.",
        "street" => "Hauptstraße 42",
        "zip_code" => "80333",
        "city" => "München",
        "name_of_student" => "Anna Mustermann",
        "class_name" => "5a",
        "teacher_name" => "Schmidt",
        "teacher_salutation" => "Frau",
        "child_type" => "meine_tochter",
        "reason" => "arzttermin",
        "start_date" => "2025-01-15",
        "end_date" => "2025-01-15"
      }

      conn = post(conn, ~p"/api/v2.1/schools/#{school.slug}/documents", params)

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/pdf"]
      # Single day should have just one date in filename
      assert [filename] = get_resp_header(conn, "content-disposition")
      assert filename =~ "2025-01-15.pdf"
      refute filename =~ "bis"
    end

    test "returns error when required fields are missing", %{conn: conn, school: school} do
      params = %{
        "type" => "entschuldigung",
        "first_name" => "Max"
        # Missing other required fields
      }

      conn = post(conn, ~p"/api/v2.1/schools/#{school.slug}/documents", params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["error"] =~ "Missing required fields"
    end

    test "returns error when school not found", %{conn: conn} do
      params = %{
        "type" => "entschuldigung",
        "first_name" => "Max",
        "last_name" => "Mustermann",
        "zip_code" => "80333",
        "city" => "München",
        "name_of_student" => "Anna Mustermann",
        "class_name" => "5a",
        "reason" => "krankheit",
        "start_date" => "2025-01-15",
        "end_date" => "2025-01-17"
      }

      conn = post(conn, ~p"/api/v2.1/schools/nonexistent-school/documents", params)

      assert json_response(conn, 404)
      response = json_response(conn, 404)
      assert response["error"] == "School not found"
    end

    test "returns error when document type is missing", %{conn: conn, school: school} do
      params = %{
        "first_name" => "Max",
        "last_name" => "Mustermann",
        "zip_code" => "80333",
        "city" => "München",
        "name_of_student" => "Anna Mustermann",
        "class_name" => "5a"
      }

      conn = post(conn, ~p"/api/v2.1/schools/#{school.slug}/documents", params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["error"] =~ "Invalid document type"
    end

    test "returns error when document type is invalid", %{conn: conn, school: school} do
      params = %{
        "type" => "invalid_type",
        "first_name" => "Max",
        "last_name" => "Mustermann",
        "zip_code" => "80333",
        "city" => "München",
        "name_of_student" => "Anna Mustermann",
        "class_name" => "5a"
      }

      conn = post(conn, ~p"/api/v2.1/schools/#{school.slug}/documents", params)

      assert json_response(conn, 400)
      response = json_response(conn, 400)
      assert response["error"] =~ "Invalid document type"
    end
  end

  describe "POST /api/v2.1/schools/:slug/documents - Beurlaubung" do
    test "creates PDF with valid data", %{conn: conn, school: school} do
      params = %{
        "type" => "beurlaubung",
        "first_name" => "Max",
        "last_name" => "Mustermann",
        "zip_code" => "80333",
        "city" => "München",
        "name_of_student" => "Anna Mustermann",
        "class_name" => "5a",
        "start_date" => "2025-02-10",
        "end_date" => "2025-02-14",
        "detailed_reason" => "Familiäre Angelegenheiten"
      }

      conn = post(conn, ~p"/api/v2.1/schools/#{school.slug}/documents", params)

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/pdf"]

      assert [filename] = get_resp_header(conn, "content-disposition")
      assert filename =~ "Beurlaubung_Anna_Mustermann"
      assert filename =~ "2025-02-10_bis_2025-02-14.pdf"
    end
  end

  describe "POST /api/v2.1/schools/:slug/documents - Sportbefreiung" do
    test "creates PDF with single lesson duration", %{conn: conn, school: school} do
      params = %{
        "type" => "sportbefreiung",
        "first_name" => "Max",
        "last_name" => "Mustermann",
        "zip_code" => "80333",
        "city" => "München",
        "name_of_student" => "Anna Mustermann",
        "class_name" => "5a",
        "duration_type" => "single_lesson",
        "single_date" => "2025-03-20",
        "detailed_reason" => "Verletzung am Fuß",
        "medical_certificate" => true
      }

      conn = post(conn, ~p"/api/v2.1/schools/#{school.slug}/documents", params)

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/pdf"]

      assert [filename] = get_resp_header(conn, "content-disposition")
      assert filename =~ "Sportbefreiung_Anna_Mustermann"
      assert filename =~ "2025-03-20.pdf"
    end

    test "creates PDF with multiple days duration", %{conn: conn, school: school} do
      params = %{
        "type" => "sportbefreiung",
        "first_name" => "Max",
        "last_name" => "Mustermann",
        "zip_code" => "80333",
        "city" => "München",
        "name_of_student" => "Anna Mustermann",
        "class_name" => "5a",
        "duration_type" => "multiple_days",
        "start_date" => "2025-03-20",
        "end_date" => "2025-04-10",
        "detailed_reason" => "Ärztliches Attest liegt bei"
      }

      conn = post(conn, ~p"/api/v2.1/schools/#{school.slug}/documents", params)

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/pdf"]

      assert [filename] = get_resp_header(conn, "content-disposition")
      assert filename =~ "Sportbefreiung_Anna_Mustermann"
      assert filename =~ "2025-03-20_bis_2025-04-10.pdf"
    end
  end

  describe "POST /api/v2.1/schools/:slug/documents - Date handling" do
    test "handles invalid date formats gracefully", %{conn: conn, school: school} do
      params = %{
        "type" => "entschuldigung",
        "first_name" => "Max",
        "last_name" => "Mustermann",
        "zip_code" => "80333",
        "city" => "München",
        "name_of_student" => "Anna Mustermann",
        "class_name" => "5a",
        "reason" => "krankheit",
        "start_date" => "invalid-date",
        "end_date" => "2025-01-17"
      }

      # Should still create PDF with today's date as fallback
      conn = post(conn, ~p"/api/v2.1/schools/#{school.slug}/documents", params)

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/pdf"]
    end
  end

  describe "POST /api/v2.1/schools/:slug/documents - Special characters" do
    test "handles special characters in student name", %{conn: conn, school: school} do
      params = %{
        "type" => "entschuldigung",
        "first_name" => "Max",
        "last_name" => "Mustermann",
        "zip_code" => "80333",
        "city" => "München",
        "name_of_student" => "Müller-Östergaard",
        "class_name" => "5a",
        "reason" => "krankheit",
        "start_date" => "2025-01-15",
        "end_date" => "2025-01-17"
      }

      conn = post(conn, ~p"/api/v2.1/schools/#{school.slug}/documents", params)

      assert conn.status == 200
      assert [filename] = get_resp_header(conn, "content-disposition")
      # Should preserve German umlauts in filename
      assert filename =~ "Müller-Östergaard"
    end
  end
end
