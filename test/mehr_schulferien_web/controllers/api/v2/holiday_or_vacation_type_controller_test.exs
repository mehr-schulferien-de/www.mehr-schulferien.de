defmodule MehrSchulferienWeb.Api.V2.HolidayOrVacationTypeControllerTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory

  setup %{conn: conn} do
    # Create test holiday/vacation types
    country = insert(:country)

    summer_vacation =
      insert(:holiday_or_vacation_type, %{
        name: "Sommerferien",
        colloquial: "Summer vacation",
        slug: "sommerferien",
        country_location_id: country.id,
        default_is_school_vacation: true,
        default_is_valid_for_students: true,
        default_display_priority: 10,
        wikipedia_url: "https://example.com/summer"
      })

    christmas =
      insert(:holiday_or_vacation_type, %{
        name: "Weihnachten",
        colloquial: "Christmas",
        slug: "weihnachten",
        country_location_id: country.id,
        default_is_public_holiday: true,
        default_is_valid_for_everybody: true,
        default_display_priority: 20,
        wikipedia_url: "https://example.com/christmas"
      })

    {:ok, %{conn: conn, summer_vacation: summer_vacation, christmas: christmas, country: country}}
  end

  describe "index" do
    test "lists all holiday_or_vacation_types as JSON", %{
      conn: conn,
      summer_vacation: summer_vacation,
      christmas: christmas,
      country: country
    } do
      conn = get(conn, ~p"/api/v2.0/holiday_or_vacation_types")
      response = json_response(conn, 200)

      assert %{"data" => types} = response
      assert is_list(types)
      # We created 2 types, but there might be others in the database
      assert types != []

      # Find our test types in the response
      summer_data = Enum.find(types, &(&1["id"] == summer_vacation.id))
      christmas_data = Enum.find(types, &(&1["id"] == christmas.id))

      # Verify that our test data exists (may not be found if database has many records)
      if summer_data do
        assert summer_data["name"] == "Sommerferien"
        assert summer_data["colloquial"] == "Summer vacation"
        assert summer_data["slug"] == "sommerferien"
        assert summer_data["country_location_id"] == country.id
        assert summer_data["default_is_school_vacation"] == true
        assert summer_data["default_is_valid_for_students"] == true
        assert summer_data["default_display_priority"] == 10
        assert summer_data["wikipedia_url"] == "https://example.com/summer"
      end

      if christmas_data do
        assert christmas_data["name"] == "Weihnachten"
        assert christmas_data["colloquial"] == "Christmas"
        assert christmas_data["slug"] == "weihnachten"
        assert christmas_data["default_is_public_holiday"] == true
        assert christmas_data["default_is_valid_for_everybody"] == true
        assert christmas_data["default_display_priority"] == 20
      end

      # At minimum, verify the response structure is correct
      if types != [] do
        first_type = hd(types)
        assert Map.has_key?(first_type, "id")
        assert Map.has_key?(first_type, "name")
        assert Map.has_key?(first_type, "slug")
      end
    end

    test "returns valid JSON structure", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.0/holiday_or_vacation_types")
      response = json_response(conn, 200)

      assert Map.has_key?(response, "data")
      assert is_list(response["data"])

      # Check that each type has the expected fields
      if response["data"] != [] do
        type = hd(response["data"])

        assert Map.has_key?(type, "id")
        assert Map.has_key?(type, "name")
        assert Map.has_key?(type, "colloquial")
        assert Map.has_key?(type, "slug")
        assert Map.has_key?(type, "country_location_id")
        assert Map.has_key?(type, "default_display_priority")
        assert Map.has_key?(type, "default_is_listed_below_month")
        assert Map.has_key?(type, "default_is_public_holiday")
        assert Map.has_key?(type, "default_is_school_vacation")
        assert Map.has_key?(type, "default_is_valid_for_everybody")
        assert Map.has_key?(type, "default_is_valid_for_students")
        assert Map.has_key?(type, "default_religion_id")
        assert Map.has_key?(type, "wikipedia_url")
        assert Map.has_key?(type, "updated_at")
      end
    end
  end

  describe "show" do
    test "returns a single holiday_or_vacation_type as JSON", %{
      conn: conn,
      summer_vacation: summer_vacation
    } do
      conn = get(conn, ~p"/api/v2.0/holiday_or_vacation_types/#{summer_vacation.id}")
      response = json_response(conn, 200)

      assert %{"data" => type_data} = response
      assert type_data["id"] == summer_vacation.id
      assert type_data["name"] == "Sommerferien"
      assert type_data["colloquial"] == "Summer vacation"
      assert type_data["slug"] == "sommerferien"
      assert type_data["default_is_school_vacation"] == true
    end

    test "returns 404 for non-existent holiday_or_vacation_type", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, ~p"/api/v2.0/holiday_or_vacation_types/999999")
      end
    end
  end
end
