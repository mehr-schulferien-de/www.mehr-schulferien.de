defmodule MehrSchulferienWeb.Api.V21.SchoolControllerTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory

  setup %{conn: conn} do
    # Create location hierarchy
    country = insert(:country, %{name: "Deutschland", slug: "deutschland"})

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

    # Create multiple schools
    schools = [
      insert(:school, %{
        name: "Gymnasium München Nord",
        slug: "gymnasium-muenchen-nord",
        parent_location_id: city.id
      }),
      insert(:school, %{
        name: "Realschule München Süd",
        slug: "realschule-muenchen-sued",
        parent_location_id: city.id
      }),
      insert(:school, %{
        name: "Hauptschule München West",
        slug: "hauptschule-muenchen-west",
        parent_location_id: city.id
      })
    ]

    # Create vacation types
    school_vacation_type =
      insert(:holiday_or_vacation_type, %{
        name: "Osterferien",
        default_is_school_vacation: true,
        country_location_id: country.id
      })

    school_specific_type =
      insert(:holiday_or_vacation_type, %{
        name: "Beweglicher Ferientag",
        colloquial: "Beweglicher Ferientag",
        default_is_school_vacation: true,
        country_location_id: country.id
      })

    # Create periods
    gymnasium = List.first(schools)

    periods = [
      # Period inherited from federal state
      insert(:period, %{
        location_id: federal_state.id,
        starts_on: ~D[2024-03-25],
        ends_on: ~D[2024-04-06],
        holiday_or_vacation_type_id: school_vacation_type.id,
        is_school_vacation: true,
        is_valid_for_students: true,
        created_by_email_address: "test@example.com"
      }),
      # School-specific period
      insert(:period, %{
        location_id: gymnasium.id,
        starts_on: ~D[2024-05-10],
        ends_on: ~D[2024-05-10],
        holiday_or_vacation_type_id: school_specific_type.id,
        is_school_vacation: true,
        is_valid_for_students: true,
        created_by_email_address: "test@example.com"
      })
    ]

    {:ok,
     %{
       conn: conn,
       country: country,
       federal_state: federal_state,
       county: county,
       city: city,
       schools: schools,
       periods: periods,
       school_vacation_type: school_vacation_type,
       school_specific_type: school_specific_type
     }}
  end

  describe "index" do
    test "lists all schools", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/schools")

      response = json_response(conn, 200)
      assert %{"data" => data, "meta" => meta} = response
      assert meta["api_version"] == "2.1"

      # Check that all schools are included
      slugs = Enum.map(data, & &1["slug"])
      assert "gymnasium-muenchen-nord" in slugs
      assert "realschule-muenchen-sued" in slugs
      assert "hauptschule-muenchen-west" in slugs
    end

    test "returns proper JSON structure", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/schools")

      response = json_response(conn, 200)
      [first_school | _] = response["data"]

      # Check structure
      assert Map.has_key?(first_school, "id")
      assert Map.has_key?(first_school, "name")
      assert Map.has_key?(first_school, "slug")
      assert Map.has_key?(first_school, "type")
      assert first_school["type"] == "school"
      assert Map.has_key?(first_school, "parent_location_id")

      # Check links
      assert Map.has_key?(first_school, "links")
      assert first_school["links"]["self"] =~ "/api/v2.1/schools/"
      assert first_school["links"]["periods"] =~ "/periods"
      assert first_school["links"]["icalendar"] =~ "/icalendar"
    end
  end

  describe "show" do
    test "returns a specific school", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/schools/gymnasium-muenchen-nord")

      response = json_response(conn, 200)
      assert response["data"]["name"] == "Gymnasium München Nord"
      assert response["data"]["slug"] == "gymnasium-muenchen-nord"
      assert response["data"]["type"] == "school"
    end

    test "returns 404 for non-existent school", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/schools/nonexistent-school")

      response = json_response(conn, 404)
      assert %{"errors" => [error]} = response
      assert error["status"] == "404"
      assert error["title"] == "Not Found"
    end

    test "only returns schools, not other location types", %{conn: conn, city: city} do
      # Try to access a city via the schools endpoint
      conn = get(conn, ~p"/api/v2.1/schools/#{city.slug}")

      response = json_response(conn, 404)
      assert %{"errors" => [_error]} = response
    end
  end

  describe "periods" do
    test "returns periods for a school including inherited ones", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/v2.1/schools/gymnasium-muenchen-nord/periods?start_date=2024-03-01&end_date=2024-05-31"
        )

      response = json_response(conn, 200)
      # Should include both the federal state period and school-specific period
      assert length(response["data"]) == 2

      names = Enum.map(response["data"], & &1["name"])
      assert "Osterferien" in names
      assert "Beweglicher Ferientag" in names
    end

    test "filters periods by date range", %{conn: conn} do
      # Query only for May 2024
      conn =
        get(
          conn,
          ~p"/api/v2.1/schools/gymnasium-muenchen-nord/periods?start_date=2024-05-01&end_date=2024-05-31"
        )

      response = json_response(conn, 200)
      # Should only return the school-specific holiday
      assert length(response["data"]) == 1
      assert List.first(response["data"])["name"] == "Beweglicher Ferientag"
    end

    test "returns empty list when no periods match date range", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/v2.1/schools/gymnasium-muenchen-nord/periods?start_date=2024-07-01&end_date=2024-07-31"
        )

      response = json_response(conn, 200)
      assert response["data"] == []
    end

    test "period response includes all required fields", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/v2.1/schools/gymnasium-muenchen-nord/periods?start_date=2024-03-01&end_date=2024-05-31"
        )

      response = json_response(conn, 200)
      [period | _] = response["data"]

      # Check all fields are present
      assert Map.has_key?(period, "id")
      assert Map.has_key?(period, "starts_on")
      assert Map.has_key?(period, "ends_on")
      assert Map.has_key?(period, "name")
      assert Map.has_key?(period, "type")
      assert Map.has_key?(period, "is_school_vacation")
      assert Map.has_key?(period, "is_public_holiday")
      assert Map.has_key?(period, "location_id")
    end
  end

  describe "icalendar" do
    test "returns iCalendar for school vacations", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/v2.1/schools/gymnasium-muenchen-nord/icalendar?vacation_types=school&year=2024&calendar_year=true"
        )

      assert response_content_type(conn, :ics)
      response = response(conn, 200)

      # Check basic iCal structure
      assert String.contains?(response, "BEGIN:VCALENDAR")
      assert String.contains?(response, "END:VCALENDAR")
      assert String.contains?(response, "PRODID:-//mehr-schulferien.de//Mehr-Schulferien//DE")

      # Check events
      assert String.contains?(response, "BEGIN:VEVENT")
      assert String.contains?(response, "SUMMARY:Osterferien (Gymnasium München Nord)")
      assert String.contains?(response, "SUMMARY:Beweglicher Ferientag (Gymnasium München Nord)")
    end

    test "filters by vacation_types parameter", %{conn: conn, schools: schools} do
      # Create a public holiday
      public_holiday_type =
        insert(:holiday_or_vacation_type, %{
          name: "Maifeiertag",
          default_is_public_holiday: true,
          default_is_school_vacation: false
        })

      insert(:period, %{
        location_id: List.first(schools).parent_location_id,
        starts_on: ~D[2024-05-01],
        ends_on: ~D[2024-05-01],
        holiday_or_vacation_type_id: public_holiday_type.id,
        is_public_holiday: true,
        is_school_vacation: false
      })

      # Request only school vacations
      conn =
        get(
          conn,
          ~p"/api/v2.1/schools/gymnasium-muenchen-nord/icalendar?vacation_types=school&year=2024"
        )

      response = response(conn, 200)

      # Should not contain the public holiday
      refute String.contains?(response, "Maifeiertag")

      # Request all types
      conn =
        build_conn()
        |> get(
          ~p"/api/v2.1/schools/gymnasium-muenchen-nord/icalendar?vacation_types=all&year=2024&calendar_year=true"
        )

      response = response(conn, 200)

      # Should contain the public holiday
      assert String.contains?(response, "Maifeiertag")
    end

    test "uses calendar year when calendar_year=true", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/v2.1/schools/gymnasium-muenchen-nord/icalendar?year=2024&calendar_year=true"
        )

      content_disposition =
        Enum.find_value(conn.resp_headers, fn {header, value} ->
          if header == "content-disposition", do: value, else: nil
        end)

      # Should show single year in filename
      assert content_disposition =~ "_2024.ics"
      refute content_disposition =~ "_2024-2025.ics"
    end

    test "uses school year by default", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/schools/gymnasium-muenchen-nord/icalendar?year=2024")

      content_disposition =
        Enum.find_value(conn.resp_headers, fn {header, value} ->
          if header == "content-disposition", do: value, else: nil
        end)

      # Should show school year format in filename
      assert content_disposition =~ "Schuljahr_2024-2025.ics"
    end

    test "handles missing year parameter", %{conn: conn} do
      current_year = Date.utc_today().year
      conn = get(conn, ~p"/api/v2.1/schools/gymnasium-muenchen-nord/icalendar")

      assert response_content_type(conn, :ics)

      content_disposition =
        Enum.find_value(conn.resp_headers, fn {header, value} ->
          if header == "content-disposition", do: value, else: nil
        end)

      # Should use current year
      assert content_disposition =~ "#{current_year}"
    end

    test "returns 404 for non-existent school", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/schools/nonexistent/icalendar")

      response = json_response(conn, 404)
      assert %{"errors" => [error]} = response
      assert error["detail"] == "The requested resource could not be found."
    end
  end
end
