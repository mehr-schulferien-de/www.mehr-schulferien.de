defmodule MehrSchulferienWeb.Api.V21.CountyControllerTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  setup %{conn: conn} do
    # Use shared helper for common setup
    %{country: country, federal_state: federal_state} = setup_api_test_hierarchy()

    # Create multiple counties
    counties = [
      insert(:county, %{
        name: "München",
        slug: "muenchen-landkreis",
        code: "M",
        parent_location_id: federal_state.id
      }),
      insert(:county, %{
        name: "Augsburg",
        slug: "augsburg-landkreis",
        code: "A",
        parent_location_id: federal_state.id
      }),
      insert(:county, %{
        name: "Nürnberg",
        slug: "nuernberg-landkreis",
        code: "N",
        parent_location_id: federal_state.id
      })
    ]

    # Create a city with same slug to test filtering
    city =
      insert(:city, %{
        name: "München Stadt",
        slug: "muenchen-landkreis",
        parent_location_id: List.first(counties).id
      })

    # Create vacation type
    vacation_type =
      insert(:holiday_or_vacation_type, %{
        name: "Pfingstferien",
        default_is_school_vacation: true,
        country_location_id: country.id
      })

    # Create periods using factories
    muenchen_county = List.first(counties)
    weihnachts_type = insert(:holiday_or_vacation_type, %{name: "Weihnachtsferien"})

    periods = [
      # County-specific period
      insert(:school_vacation, %{
        location_id: muenchen_county.id,
        starts_on: ~D[2024-05-21],
        ends_on: ~D[2024-05-31],
        holiday_or_vacation_type_id: vacation_type.id
      }),
      # Federal state period (inherited)
      insert(:school_vacation, %{
        location_id: federal_state.id,
        starts_on: ~D[2024-12-23],
        ends_on: ~D[2025-01-06],
        holiday_or_vacation_type_id: weihnachts_type.id
      })
    ]

    {:ok,
     %{
       conn: conn,
       country: country,
       federal_state: federal_state,
       counties: counties,
       city: city,
       periods: periods,
       vacation_type: vacation_type
     }}
  end

  describe "index" do
    test "lists all counties", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/counties")

      response = json_response(conn, 200)
      assert %{"data" => data, "meta" => meta} = response
      assert meta["api_version"] == "2.1"

      # Check that all counties are included
      slugs = Enum.map(data, & &1["slug"])
      assert "muenchen-landkreis" in slugs
      assert "augsburg-landkreis" in slugs
      assert "nuernberg-landkreis" in slugs

      # Verify they're all counties
      Enum.each(data, fn county ->
        assert county["type"] == "county"
      end)
    end

    test "returns proper JSON structure", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/counties")

      response = json_response(conn, 200)
      [first_county | _] = response["data"]

      # Check structure
      assert Map.has_key?(first_county, "id")
      assert Map.has_key?(first_county, "name")
      assert Map.has_key?(first_county, "slug")
      assert Map.has_key?(first_county, "code")
      assert Map.has_key?(first_county, "type")
      assert first_county["type"] == "county"
      assert Map.has_key?(first_county, "parent_location_id")

      # Check links
      assert Map.has_key?(first_county, "links")
      assert first_county["links"]["self"] =~ "/api/v2.1/counties/"
      assert first_county["links"]["periods"] =~ "/periods"
      assert first_county["links"]["icalendar"] =~ "/icalendar"
    end
  end

  describe "show" do
    test "returns a specific county", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/counties/muenchen-landkreis")

      response = json_response(conn, 200)
      assert response["data"]["name"] == "München"
      assert response["data"]["slug"] == "muenchen-landkreis"
      assert response["data"]["code"] == "M"
      assert response["data"]["type"] == "county"
    end

    test "returns 404 for non-existent county", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/counties/nonexistent-county")

      response = json_response(conn, 404)
      assert %{"errors" => [error]} = response
      assert error["status"] == "404"
      assert error["title"] == "Not Found"
      assert error["detail"] == "The requested resource could not be found."
    end

    test "returns 404 for non-county location with same slug", %{conn: conn, city: city} do
      # The city has the same slug but should not be accessible via counties endpoint
      conn = get(conn, ~p"/api/v2.1/counties/#{city.slug}")

      # Should return the county, not the city
      response = json_response(conn, 200)
      assert response["data"]["type"] == "county"
      assert response["data"]["name"] == "München"
    end
  end

  describe "periods" do
    test "returns periods for a county including inherited ones", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/v2.1/counties/muenchen-landkreis/periods?start_date=2024-01-01&end_date=2025-12-31"
        )

      response = json_response(conn, 200)
      # Should include both county-specific and federal state periods
      assert length(response["data"]) == 2

      names = Enum.map(response["data"], & &1["name"])
      assert "Pfingstferien" in names
      assert "Weihnachtsferien" in names
    end

    test "filters periods by date range", %{conn: conn} do
      # Query only for May 2024
      conn =
        get(
          conn,
          ~p"/api/v2.1/counties/muenchen-landkreis/periods?start_date=2024-05-01&end_date=2024-05-31"
        )

      response = json_response(conn, 200)
      # Should only return Pfingstferien
      assert length(response["data"]) == 1
      assert List.first(response["data"])["name"] == "Pfingstferien"
    end

    test "returns all periods", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/v2.1/counties/muenchen-landkreis/periods?start_date=2024-01-01&end_date=2025-12-31"
        )

      response = json_response(conn, 200)
      # Should return all periods
      assert length(response["data"]) == 2
      assert response["meta"]["date_range"]["start_date"] == "2024-01-01"
      assert response["meta"]["date_range"]["end_date"] == "2025-12-31"
    end

    test "returns proper period structure", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/v2.1/counties/muenchen-landkreis/periods?start_date=2024-05-01&end_date=2024-06-30"
        )

      response = json_response(conn, 200)
      [period | _] = response["data"]

      # Check all expected fields
      assert period["starts_on"] =~ ~r/^\d{4}-\d{2}-\d{2}$/
      assert period["ends_on"] =~ ~r/^\d{4}-\d{2}-\d{2}$/
      assert is_binary(period["name"])
      assert period["type"] in ["school_vacation", "public_holiday", "other"]
      assert is_boolean(period["is_school_vacation"])
      assert is_boolean(period["is_public_holiday"])
      assert is_integer(period["location_id"])
    end
  end

  describe "icalendar" do
    test "returns iCalendar for county", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/v2.1/counties/muenchen-landkreis/icalendar?vacation_types=school&year=2024&calendar_year=true"
        )

      assert response_content_type(conn, :ics)
      response = response(conn, 200)

      # Check iCal structure
      assert String.contains?(response, "BEGIN:VCALENDAR")
      assert String.contains?(response, "VERSION:2.0")
      assert String.contains?(response, "PRODID:-//mehr-schulferien.de//Mehr-Schulferien//DE")
      assert String.contains?(response, "END:VCALENDAR")

      # Check events - should include both county and federal state periods
      assert String.contains?(response, "SUMMARY:Pfingstferien (München)")
      assert String.contains?(response, "DTSTART;VALUE=DATE:20240521")
      # Exclusive end date
      assert String.contains?(response, "DTEND;VALUE=DATE:20240601")

      assert String.contains?(response, "SUMMARY:Weihnachtsferien (München)")
    end

    test "filters by vacation_types", %{conn: conn, federal_state: federal_state} do
      # Add a public holiday using factory
      holiday_type =
        insert(:holiday_or_vacation_type, %{
          name: "Fronleichnam",
          default_is_public_holiday: true,
          default_is_school_vacation: false
        })

      insert(:public_holiday, %{
        location_id: federal_state.id,
        starts_on: ~D[2024-05-30],
        ends_on: ~D[2024-05-30],
        holiday_or_vacation_type_id: holiday_type.id
      })

      # Request only school vacations
      conn =
        get(
          conn,
          ~p"/api/v2.1/counties/muenchen-landkreis/icalendar?vacation_types=school&year=2024&calendar_year=true"
        )

      response = response(conn, 200)

      # Should not contain the public holiday
      refute String.contains?(response, "Fronleichnam")

      # Request all types
      conn =
        build_conn()
        |> get(
          ~p"/api/v2.1/counties/muenchen-landkreis/icalendar?vacation_types=all&year=2024&calendar_year=true"
        )

      response = response(conn, 200)

      # Should contain both vacations and holidays
      assert String.contains?(response, "Pfingstferien")
      assert String.contains?(response, "Fronleichnam")
    end

    test "respects calendar_year parameter", %{conn: conn} do
      # Calendar year
      conn =
        get(
          conn,
          ~p"/api/v2.1/counties/muenchen-landkreis/icalendar?year=2024&calendar_year=true"
        )

      content_disposition =
        Enum.find_value(conn.resp_headers, fn {header, value} ->
          if header == "content-disposition", do: value, else: nil
        end)

      assert content_disposition =~ "_2024.ics"

      # School year (default)
      conn = build_conn() |> get(~p"/api/v2.1/counties/muenchen-landkreis/icalendar?year=2024")

      content_disposition =
        Enum.find_value(conn.resp_headers, fn {header, value} ->
          if header == "content-disposition", do: value, else: nil
        end)

      assert content_disposition =~ "Schuljahr_2024-2025.ics"
    end

    test "handles invalid parameters gracefully", %{conn: conn} do
      # Invalid year
      conn = get(conn, ~p"/api/v2.1/counties/muenchen-landkreis/icalendar?year=invalid")

      # Should default to current year
      assert response_content_type(conn, :ics)
      response = response(conn, 200)
      assert String.contains?(response, "BEGIN:VCALENDAR")
    end

    test "returns 404 for non-existent county", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.1/counties/nonexistent/icalendar")

      response = json_response(conn, 404)
      assert %{"errors" => [error]} = response
      assert error["status"] == "404"
      assert response["meta"]["api_version"] == "2.1"
    end
  end
end
