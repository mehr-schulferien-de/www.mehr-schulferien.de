defmodule MehrSchulferienWeb.Api.V21.CityControllerTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

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

    # Create multiple cities
    cities = [
      insert(:city, %{
        name: "München",
        slug: "muenchen",
        parent_location_id: county.id
      }),
      insert(:city, %{
        name: "Augsburg",
        slug: "augsburg",
        parent_location_id: county.id
      }),
      insert(:city, %{
        name: "Nürnberg",
        slug: "nuernberg",
        parent_location_id: county.id
      })
    ]

    # Create a school with same slug to test filtering
    school =
      insert(:school, %{
        name: "München Gymnasium",
        slug: "muenchen",
        parent_location_id: List.first(cities).id
      })

    # Create vacation type
    vacation_type =
      insert(:holiday_or_vacation_type, %{
        name: "Herbstferien",
        default_is_school_vacation: true,
        country_location_id: country.id
      })

    # Create periods for München
    muenchen = List.first(cities)

    periods = [
      insert(:period, %{
        location_id: muenchen.id,
        starts_on: ~D[2024-10-28],
        ends_on: ~D[2024-11-01],
        holiday_or_vacation_type_id: vacation_type.id,
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
       cities: cities,
       school: school,
       periods: periods,
       vacation_type: vacation_type
     }}
  end

  describe "index" do
    test "lists all cities", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/cities")

      response = json_response(conn, 200)
      assert %{"data" => data, "meta" => meta} = response
      assert meta["api_version"] == "2.1"

      # Check that all cities are included
      slugs = Enum.map(data, & &1["slug"])
      assert "muenchen" in slugs
      assert "augsburg" in slugs
      assert "nuernberg" in slugs
    end

    test "returns proper JSON structure", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/cities")

      response = json_response(conn, 200)
      [first_city | _] = response["data"]

      # Check structure
      assert Map.has_key?(first_city, "id")
      assert Map.has_key?(first_city, "name")
      assert Map.has_key?(first_city, "slug")
      assert Map.has_key?(first_city, "type")
      assert first_city["type"] == "city"

      # Check links
      assert Map.has_key?(first_city, "links")
      assert Map.has_key?(first_city["links"], "self")
      assert Map.has_key?(first_city["links"], "periods")
      assert Map.has_key?(first_city["links"], "icalendar")
    end
  end

  describe "show" do
    test "returns a specific city", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/cities/muenchen")

      response = json_response(conn, 200)
      assert response["data"]["name"] == "München"
      assert response["data"]["slug"] == "muenchen"
      assert response["data"]["type"] == "city"
    end

    test "returns 404 for non-existent city", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/cities/nonexistent")

      response = json_response(conn, 404)
      assert %{"errors" => [error]} = response
      assert error["status"] == "404"
    end

    test "returns 404 for non-city location with same slug", %{conn: conn, school: school} do
      # The school has slug "muenchen" but accessing via cities endpoint should still return the city
      conn = get(conn, ~p"/api/v2.1/cities/#{school.slug}")

      response = json_response(conn, 200)
      assert response["data"]["name"] == "München"
      assert response["data"]["type"] == "city"
    end
  end

  describe "periods" do
    test "returns periods for a city", %{conn: conn} do
      conn =
        get(conn, ~p"/api/v2.1/cities/muenchen/periods?start_date=2024-10-01&end_date=2024-11-30")

      response = json_response(conn, 200)
      assert length(response["data"]) == 1

      # Check period structure
      [period] = response["data"]
      assert period["name"] == "Herbstferien"
      assert period["starts_on"] == "2024-10-28"
      assert period["ends_on"] == "2024-11-01"
      assert period["is_school_vacation"] == true
    end

    test "filters periods by date range", %{conn: conn} do
      # Query outside the vacation period
      conn =
        get(conn, ~p"/api/v2.1/cities/muenchen/periods?start_date=2024-12-01&end_date=2024-12-31")

      response = json_response(conn, 200)
      assert response["data"] == []
    end

    test "includes inherited periods from parent locations", %{
      conn: conn,
      federal_state: federal_state
    } do
      # Add a period to the federal state
      vacation_type = insert(:holiday_or_vacation_type, %{name: "Winterferien"})

      insert(:period, %{
        location_id: federal_state.id,
        starts_on: ~D[2024-12-23],
        ends_on: ~D[2025-01-06],
        holiday_or_vacation_type_id: vacation_type.id,
        is_school_vacation: true,
        is_valid_for_students: true,
        created_by_email_address: "test@example.com"
      })

      conn =
        get(conn, ~p"/api/v2.1/cities/muenchen/periods?start_date=2024-01-01&end_date=2025-12-31")

      response = json_response(conn, 200)
      # Should include both city period and inherited federal state period
      assert length(response["data"]) == 2

      names = Enum.map(response["data"], & &1["name"])
      assert "Herbstferien" in names
      assert "Winterferien" in names
    end
  end

  describe "icalendar" do
    test "returns iCalendar for city", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/cities/muenchen/icalendar?vacation_types=school&year=2024")

      assert response_content_type(conn, :ics)
      response = response(conn, 200)

      # Check iCal structure
      assert String.contains?(response, "BEGIN:VCALENDAR")
      assert String.contains?(response, "END:VCALENDAR")
      assert String.contains?(response, "BEGIN:VEVENT")
      assert String.contains?(response, "SUMMARY:Herbstferien (München)")
      assert String.contains?(response, "DTSTART;VALUE=DATE:20241028")
      # iCal uses exclusive end date
      assert String.contains?(response, "DTEND;VALUE=DATE:20241102")
    end

    test "includes proper headers", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/cities/muenchen/icalendar?vacation_types=school&year=2024")

      # Check content type
      assert response_content_type(conn, :ics)

      # Check content-disposition header
      content_disposition =
        Enum.find_value(conn.resp_headers, fn {header, value} ->
          if header == "content-disposition", do: value, else: nil
        end)

      assert content_disposition =~ "attachment"
      assert content_disposition =~ "München"
      assert content_disposition =~ ".ics"
    end

    test "returns 404 for non-existent city", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/cities/nonexistent/icalendar")

      response = json_response(conn, 404)
      assert %{"errors" => [_error]} = response
    end
  end
end
