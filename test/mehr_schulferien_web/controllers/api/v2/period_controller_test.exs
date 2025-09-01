defmodule MehrSchulferienWeb.Api.V2.PeriodControllerTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory

  setup %{conn: conn} do
    # Create test data
    location = insert(:federal_state)
    holiday_type = insert(:holiday_or_vacation_type, %{name: "Test Holiday"})

    period1 =
      insert(:period, %{
        starts_on: ~D[2025-01-01],
        ends_on: ~D[2025-01-07],
        location_id: location.id,
        holiday_or_vacation_type_id: holiday_type.id,
        memo: "Test period 1",
        display_priority: 10,
        is_school_vacation: true,
        is_valid_for_students: true
      })

    period2 =
      insert(:period, %{
        starts_on: ~D[2025-06-01],
        ends_on: ~D[2025-06-15],
        location_id: location.id,
        holiday_or_vacation_type_id: holiday_type.id,
        memo: "Test period 2",
        display_priority: 5,
        is_public_holiday: true,
        is_valid_for_everybody: true
      })

    {:ok, %{conn: conn, period1: period1, period2: period2}}
  end

  describe "index" do
    test "lists all periods as JSON", %{conn: conn, period1: period1, period2: period2} do
      conn = get(conn, ~p"/api/v2.0/periods")
      response = json_response(conn, 200)

      assert %{"data" => periods} = response
      assert is_list(periods)
      assert length(periods) >= 2

      # Find our test periods in the response
      period1_data = Enum.find(periods, &(&1["id"] == period1.id))
      period2_data = Enum.find(periods, &(&1["id"] == period2.id))

      # Verify period1 data
      assert period1_data["starts_on"] == "2025-01-01"
      assert period1_data["ends_on"] == "2025-01-07"
      assert period1_data["memo"] == "Test period 1"
      assert period1_data["display_priority"] == 10
      assert period1_data["is_school_vacation"] == true
      assert period1_data["is_valid_for_students"] == true
      assert period1_data["location_id"] == period1.location_id
      assert period1_data["holiday_or_vacation_type_id"] == period1.holiday_or_vacation_type_id

      # Verify period2 data
      assert period2_data["starts_on"] == "2025-06-01"
      assert period2_data["ends_on"] == "2025-06-15"
      assert period2_data["memo"] == "Test period 2"
      assert period2_data["display_priority"] == 5
      assert period2_data["is_public_holiday"] == true
      assert period2_data["is_valid_for_everybody"] == true
    end

    test "returns valid JSON structure", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.0/periods")
      response = json_response(conn, 200)

      assert Map.has_key?(response, "data")
      assert is_list(response["data"])

      # Check that each period has the expected fields
      if length(response["data"]) > 0 do
        period = hd(response["data"])

        assert Map.has_key?(period, "id")
        assert Map.has_key?(period, "starts_on")
        assert Map.has_key?(period, "ends_on")
        assert Map.has_key?(period, "location_id")
        assert Map.has_key?(period, "holiday_or_vacation_type_id")
        assert Map.has_key?(period, "is_school_vacation")
        assert Map.has_key?(period, "is_public_holiday")
        assert Map.has_key?(period, "is_valid_for_students")
        assert Map.has_key?(period, "is_valid_for_everybody")
      end
    end
  end

  describe "show" do
    test "returns a single period as JSON", %{conn: conn, period1: period1} do
      conn = get(conn, ~p"/api/v2.0/periods/#{period1.id}")
      response = json_response(conn, 200)

      assert %{"data" => period_data} = response
      assert period_data["id"] == period1.id
      assert period_data["starts_on"] == "2025-01-01"
      assert period_data["ends_on"] == "2025-01-07"
      assert period_data["memo"] == "Test period 1"
      assert period_data["is_school_vacation"] == true
    end

    test "returns 404 for non-existent period", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, ~p"/api/v2.0/periods/999999")
      end
    end
  end
end