defmodule MehrSchulferienWeb.WikiApprovalControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.{Locations, Periods, Repo}
  alias MehrSchulferien.Wiki.PendingChange
  alias MehrSchulferien.Wiki.PendingChanges
  import MehrSchulferien.Factory

  describe "approve/2 for create_school" do
    setup do
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)
      county = insert(:county, parent_location_id: federal_state.id)
      city = insert(:city, parent_location_id: county.id)
      zip_code = insert(:zip_code, value: "12345")

      insert(:zip_code_mapping, %{
        location_id: city.id,
        zip_code_id: zip_code.id,
        lat: 52.52,
        lon: 13.405
      })

      %{city: city, country: country}
    end

    test "approves valid pending change and shows success page", %{conn: conn, city: city} do
      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_school",
          payload: %{
            "school_name" => "Test Gymnasium",
            "address_params" => %{
              "street" => "Schulstraße 1",
              "zip_code" => "12345",
              "city" => "Berlin"
            },
            "city_id" => city.id,
            "zip_code" => "12345"
          },
          submitted_by_ip: "127.0.0.1"
        })

      conn = get(conn, ~p"/wiki/approve/#{pending_change.approval_token}")

      response = html_response(conn, 200)
      assert response =~ "Änderung genehmigt"

      # Verify pending change was updated
      updated = Repo.get!(PendingChange, pending_change.id)
      assert updated.status == "approved"
    end
  end

  describe "approve/2 error cases" do
    test "shows error for invalid token", %{conn: conn} do
      conn = get(conn, ~p"/wiki/approve/invalid-token-12345")

      response = html_response(conn, 200)
      assert response =~ "Fehler"
    end

    test "shows already processed page for already approved change", %{conn: conn} do
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)
      county = insert(:county, parent_location_id: federal_state.id)
      city = insert(:city, parent_location_id: county.id)
      zip_code = insert(:zip_code, value: "11111")

      insert(:zip_code_mapping, %{
        location_id: city.id,
        zip_code_id: zip_code.id,
        lat: 52.52,
        lon: 13.405
      })

      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_school",
          payload: %{
            "school_name" => "Already Approved School",
            "address_params" => %{
              "street" => "Teststraße 1",
              "zip_code" => "11111",
              "city" => "Berlin"
            },
            "city_id" => city.id,
            "zip_code" => "11111"
          },
          submitted_by_ip: "127.0.0.1"
        })

      # Approve it first
      {:ok, _} = PendingChanges.approve_change!(pending_change)

      # Try to approve again via controller
      conn = get(conn, ~p"/wiki/approve/#{pending_change.approval_token}")

      response = html_response(conn, 200)
      assert response =~ "Bereits verarbeitet"
    end

    test "shows already processed page for rejected change", %{conn: conn} do
      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_school",
          payload: %{"school_name" => "Rejected School"},
          submitted_by_ip: "127.0.0.1"
        })

      # Reject it first
      {:ok, _} = PendingChanges.reject_change!(pending_change)

      # Try to approve
      conn = get(conn, ~p"/wiki/approve/#{pending_change.approval_token}")

      response = html_response(conn, 200)
      assert response =~ "Bereits verarbeitet"
    end
  end

  describe "reject/2" do
    test "rejects valid pending change and shows success page", %{conn: conn} do
      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_school",
          payload: %{"school_name" => "To Be Rejected School"},
          submitted_by_ip: "127.0.0.1"
        })

      conn = get(conn, ~p"/wiki/reject/#{pending_change.rejection_token}")

      response = html_response(conn, 200)
      assert response =~ "Änderung abgelehnt"

      # Verify status was updated
      updated = Repo.get!(PendingChange, pending_change.id)
      assert updated.status == "rejected"
    end

    test "shows error for invalid token", %{conn: conn} do
      conn = get(conn, ~p"/wiki/reject/invalid-token-67890")

      response = html_response(conn, 200)
      assert response =~ "Fehler"
    end

    test "shows already processed page for already rejected change", %{conn: conn} do
      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_school",
          payload: %{"school_name" => "Already Rejected School"},
          submitted_by_ip: "127.0.0.1"
        })

      # Reject it first
      {:ok, _} = PendingChanges.reject_change!(pending_change)

      # Try to reject again
      conn = get(conn, ~p"/wiki/reject/#{pending_change.rejection_token}")

      response = html_response(conn, 200)
      assert response =~ "Bereits verarbeitet"
    end

    test "shows already processed page for approved change", %{conn: conn} do
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)
      county = insert(:county, parent_location_id: federal_state.id)
      city = insert(:city, parent_location_id: county.id)
      zip_code = insert(:zip_code, value: "54321")

      insert(:zip_code_mapping, %{
        location_id: city.id,
        zip_code_id: zip_code.id,
        lat: 52.52,
        lon: 13.405
      })

      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_school",
          payload: %{
            "school_name" => "Already Approved School 2",
            "address_params" => %{
              "street" => "Teststraße 2",
              "zip_code" => "54321",
              "city" => "Berlin"
            },
            "city_id" => city.id,
            "zip_code" => "54321"
          },
          submitted_by_ip: "127.0.0.1"
        })

      # Approve it first
      {:ok, _} = PendingChanges.approve_change!(pending_change)

      # Try to reject
      conn = get(conn, ~p"/wiki/reject/#{pending_change.rejection_token}")

      response = html_response(conn, 200)
      assert response =~ "Bereits verarbeitet"
    end
  end

  describe "approval workflow for update_school" do
    test "approves update_school change", %{conn: conn} do
      school = insert(:school, name: "Original Name")

      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "update_school",
          payload: %{
            "school_name" => "Updated Name",
            "address_params" => %{}
          },
          original_record_id: school.id,
          submitted_by_ip: "127.0.0.1"
        })

      conn = get(conn, ~p"/wiki/approve/#{pending_change.approval_token}")

      response = html_response(conn, 200)
      assert response =~ "Änderung genehmigt"

      # Verify school was updated
      updated_school = Locations.get_location(school.id)
      assert updated_school.name == "Updated Name"
    end
  end

  describe "approval workflow for delete_school" do
    test "approves delete_school change", %{conn: conn} do
      school = insert(:school, name: "School To Delete")

      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "delete_school",
          payload: %{
            "school_name" => school.name,
            "deletion_reason" => "Closed"
          },
          original_record_id: school.id,
          submitted_by_ip: "127.0.0.1"
        })

      conn = get(conn, ~p"/wiki/approve/#{pending_change.approval_token}")

      response = html_response(conn, 200)
      assert response =~ "Änderung genehmigt"

      # Verify school was deleted
      assert Locations.get_location(school.id) == nil
    end
  end

  describe "approval workflow for periods" do
    test "approves create_period change", %{conn: conn} do
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)
      vacation_type = insert(:holiday_or_vacation_type, default_is_school_vacation: true)

      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_period",
          payload: %{
            "location_id" => federal_state.id,
            "holiday_or_vacation_type_id" => vacation_type.id,
            "starts_on" => "2026-07-01",
            "ends_on" => "2026-08-15"
          },
          submitted_by_ip: "127.0.0.1"
        })

      conn = get(conn, ~p"/wiki/approve/#{pending_change.approval_token}")

      response = html_response(conn, 200)
      assert response =~ "Änderung genehmigt"

      # Verify pending change was approved
      updated = Repo.get!(PendingChange, pending_change.id)
      assert updated.status == "approved"
    end

    test "approves update_period change", %{conn: conn} do
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)
      vacation_type = insert(:holiday_or_vacation_type, default_is_school_vacation: true)

      {:ok, period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: vacation_type.id,
          starts_on: ~D[2026-07-01],
          ends_on: ~D[2026-08-15],
          created_by_email_address: "test@test.de",
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false
        })

      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "update_period",
          payload: %{
            "location_id" => federal_state.id,
            "holiday_or_vacation_type_id" => vacation_type.id,
            "starts_on" => "2026-07-05",
            "ends_on" => "2026-08-20"
          },
          original_record_id: period.id,
          submitted_by_ip: "127.0.0.1"
        })

      conn = get(conn, ~p"/wiki/approve/#{pending_change.approval_token}")

      response = html_response(conn, 200)
      assert response =~ "Änderung genehmigt"

      # Verify period was updated
      updated_period = Repo.get!(Periods.Period, period.id)
      assert updated_period.starts_on == ~D[2026-07-05]
      assert updated_period.ends_on == ~D[2026-08-20]
    end

    test "approves delete_period change", %{conn: conn} do
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)
      vacation_type = insert(:holiday_or_vacation_type, default_is_school_vacation: true)

      {:ok, period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: vacation_type.id,
          starts_on: ~D[2026-07-01],
          ends_on: ~D[2026-08-15],
          created_by_email_address: "test@test.de",
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false
        })

      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "delete_period",
          payload: %{
            "location_id" => period.location_id,
            "starts_on" => Date.to_string(period.starts_on),
            "ends_on" => Date.to_string(period.ends_on)
          },
          original_record_id: period.id,
          submitted_by_ip: "127.0.0.1"
        })

      conn = get(conn, ~p"/wiki/approve/#{pending_change.approval_token}")

      response = html_response(conn, 200)
      assert response =~ "Änderung genehmigt"

      # Verify period was deleted
      assert Repo.get(Periods.Period, period.id) == nil
    end
  end
end
