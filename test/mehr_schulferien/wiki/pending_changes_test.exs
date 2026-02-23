defmodule MehrSchulferien.Wiki.PendingChangesTest do
  use MehrSchulferien.DataCase

  alias MehrSchulferien.{Locations, Periods, Repo}
  alias MehrSchulferien.Wiki.PendingChange
  alias MehrSchulferien.Wiki.PendingChanges
  import MehrSchulferien.Factory

  describe "create_pending_change/1" do
    test "creates a pending change with valid attrs" do
      attrs = %{
        change_type: "create_school",
        payload: %{"school_name" => "Test School"},
        submitted_by_ip: "127.0.0.1"
      }

      assert {:ok, pending_change} = PendingChanges.create_pending_change(attrs)
      assert pending_change.change_type == "create_school"
      assert pending_change.payload["school_name"] == "Test School"
      assert pending_change.status == "pending"
      assert pending_change.approval_token != nil
      assert pending_change.rejection_token != nil
      assert String.length(pending_change.approval_token) > 30
      assert String.length(pending_change.rejection_token) > 30
    end

    test "creates a pending change for update_school" do
      school = insert(:school)

      attrs = %{
        change_type: "update_school",
        payload: %{"school_name" => "Updated Name"},
        original_record_id: school.id,
        submitted_by_ip: "192.168.1.1"
      }

      assert {:ok, pending_change} = PendingChanges.create_pending_change(attrs)
      assert pending_change.change_type == "update_school"
      assert pending_change.original_record_id == school.id
    end

    test "creates a pending change for delete_school" do
      school = insert(:school)

      attrs = %{
        change_type: "delete_school",
        payload: %{"school_name" => school.name, "deletion_reason" => "School closed"},
        original_record_id: school.id,
        submitted_by_ip: "127.0.0.1"
      }

      assert {:ok, pending_change} = PendingChanges.create_pending_change(attrs)
      assert pending_change.change_type == "delete_school"
    end

    test "fails with invalid change_type" do
      attrs = %{
        change_type: "invalid_type",
        payload: %{},
        submitted_by_ip: "127.0.0.1"
      }

      assert {:error, changeset} = PendingChanges.create_pending_change(attrs)
      assert "is invalid" in errors_on(changeset).change_type
    end

    test "fails without required fields" do
      assert {:error, changeset} = PendingChanges.create_pending_change(%{})
      assert "can't be blank" in errors_on(changeset).change_type
      assert "can't be blank" in errors_on(changeset).payload
    end
  end

  describe "get_by_approval_token/1" do
    test "returns pending change with valid token" do
      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_school",
          payload: %{"school_name" => "Test"},
          submitted_by_ip: "127.0.0.1"
        })

      found = PendingChanges.get_by_approval_token(pending_change.approval_token)
      assert found.id == pending_change.id
    end

    test "returns nil for invalid token" do
      assert PendingChanges.get_by_approval_token("invalid-token") == nil
    end

    test "returns nil for nil token" do
      assert PendingChanges.get_by_approval_token(nil) == nil
    end
  end

  describe "get_by_rejection_token/1" do
    test "returns pending change with valid token" do
      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_school",
          payload: %{"school_name" => "Test"},
          submitted_by_ip: "127.0.0.1"
        })

      found = PendingChanges.get_by_rejection_token(pending_change.rejection_token)
      assert found.id == pending_change.id
    end

    test "returns nil for invalid token" do
      assert PendingChanges.get_by_rejection_token("invalid-token") == nil
    end
  end

  describe "approve_change!/2 for create_school" do
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

      %{city: city}
    end

    test "creates school when approved", %{city: city} do
      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_school",
          payload: %{
            "school_name" => "Neue Testschule",
            "address_params" => %{
              "street" => "Teststraße 1",
              "zip_code" => "12345",
              "city" => "Berlin"
            },
            "city_id" => city.id,
            "zip_code" => "12345"
          },
          submitted_by_ip: "127.0.0.1"
        })

      assert {:ok, result} = PendingChanges.approve_change!(pending_change)
      assert result.school != nil
      assert result.school.name == "Neue Testschule"

      # Verify pending change status was updated
      updated_pending = Repo.get!(PendingChange, pending_change.id)
      assert updated_pending.status == "approved"
      assert updated_pending.reviewed_at != nil
    end
  end

  describe "approve_change!/2 for update_school" do
    setup do
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)
      county = insert(:county, parent_location_id: federal_state.id)
      city = insert(:city, parent_location_id: county.id)
      school = insert(:school, parent_location_id: city.id, name: "Original Name")

      %{school: school}
    end

    test "updates school when approved", %{school: school} do
      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "update_school",
          payload: %{
            "school_name" => "Updated School Name",
            "address_params" => %{"street" => "New Street 123"}
          },
          original_record_id: school.id,
          submitted_by_ip: "127.0.0.1"
        })

      assert {:ok, result} = PendingChanges.approve_change!(pending_change)
      assert result.school.name == "Updated School Name"

      # Verify pending change status was updated
      updated_pending = Repo.get!(PendingChange, pending_change.id)
      assert updated_pending.status == "approved"

      # Verify school was updated in database
      updated_school = Locations.get_location(school.id)
      assert updated_school.name == "Updated School Name"
    end
  end

  describe "approve_change!/2 for delete_school" do
    setup do
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)
      county = insert(:county, parent_location_id: federal_state.id)
      city = insert(:city, parent_location_id: county.id)
      school = insert(:school, parent_location_id: city.id)

      %{school: school}
    end

    test "deletes school when approved", %{school: school} do
      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "delete_school",
          payload: %{
            "school_name" => school.name,
            "deletion_reason" => "School closed permanently"
          },
          original_record_id: school.id,
          submitted_by_ip: "127.0.0.1"
        })

      assert {:ok, result} = PendingChanges.approve_change!(pending_change)
      # Result contains the deleted school info
      assert result.school != nil

      # Verify pending change status was updated
      updated_pending = Repo.get!(PendingChange, pending_change.id)
      assert updated_pending.status == "approved"

      # Verify school was deleted
      assert Locations.get_location(school.id) == nil
    end
  end

  describe "approve_change!/2 for create_period" do
    setup do
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)
      vacation_type = insert(:holiday_or_vacation_type, default_is_school_vacation: true)

      %{federal_state: federal_state, vacation_type: vacation_type}
    end

    test "creates period when approved", %{
      federal_state: federal_state,
      vacation_type: vacation_type
    } do
      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_period",
          payload: %{
            "location_id" => federal_state.id,
            "holiday_or_vacation_type_id" => vacation_type.id,
            "starts_on" => "2026-07-01",
            "ends_on" => "2026-08-15",
            "memo" => "Summer vacation"
          },
          submitted_by_ip: "127.0.0.1"
        })

      assert {:ok, result} = PendingChanges.approve_change!(pending_change)
      assert result.period != nil
      assert result.period.starts_on == ~D[2026-07-01]
      assert result.period.ends_on == ~D[2026-08-15]

      # Verify pending change status was updated
      updated_pending = Repo.get!(PendingChange, pending_change.id)
      assert updated_pending.status == "approved"
    end
  end

  describe "approve_change!/2 for update_period" do
    setup do
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

      %{period: period, federal_state: federal_state, vacation_type: vacation_type}
    end

    test "updates period when approved", %{
      period: period,
      federal_state: federal_state,
      vacation_type: vacation_type
    } do
      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "update_period",
          payload: %{
            "location_id" => federal_state.id,
            "holiday_or_vacation_type_id" => vacation_type.id,
            "starts_on" => "2026-07-05",
            "ends_on" => "2026-08-20",
            "memo" => "Updated dates"
          },
          original_record_id: period.id,
          submitted_by_ip: "127.0.0.1"
        })

      assert {:ok, result} = PendingChanges.approve_change!(pending_change)
      assert result.period.starts_on == ~D[2026-07-05]
      assert result.period.ends_on == ~D[2026-08-20]

      # Verify pending change status was updated
      updated_pending = Repo.get!(PendingChange, pending_change.id)
      assert updated_pending.status == "approved"

      # Verify period was updated in database
      updated_period = Repo.get!(Periods.Period, period.id)
      assert updated_period.starts_on == ~D[2026-07-05]
      assert updated_period.ends_on == ~D[2026-08-20]
    end
  end

  describe "approve_change!/2 for delete_period" do
    setup do
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

      %{period: period}
    end

    test "deletes period when approved", %{period: period} do
      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "delete_period",
          payload: %{
            "location_id" => period.location_id,
            "holiday_or_vacation_type_id" => period.holiday_or_vacation_type_id,
            "starts_on" => Date.to_string(period.starts_on),
            "ends_on" => Date.to_string(period.ends_on)
          },
          original_record_id: period.id,
          submitted_by_ip: "127.0.0.1"
        })

      assert {:ok, _result} = PendingChanges.approve_change!(pending_change)

      # Verify pending change status was updated
      updated_pending = Repo.get!(PendingChange, pending_change.id)
      assert updated_pending.status == "approved"

      # Verify period was deleted
      assert Repo.get(Periods.Period, period.id) == nil
    end
  end

  describe "reject_change!/2" do
    test "marks pending change as rejected" do
      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_school",
          payload: %{"school_name" => "Test"},
          submitted_by_ip: "127.0.0.1"
        })

      {:ok, rejected} = PendingChanges.reject_change!(pending_change)

      assert rejected.status == "rejected"
      assert rejected.reviewed_at != nil
    end

    test "can add reviewer note when rejecting" do
      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_school",
          payload: %{"school_name" => "Test"},
          submitted_by_ip: "127.0.0.1"
        })

      {:ok, rejected} =
        PendingChanges.reject_change!(pending_change, reviewer_note: "Invalid data")

      assert rejected.status == "rejected"
      assert rejected.reviewer_note == "Invalid data"
    end
  end

  describe "list_pending/1" do
    test "returns only pending changes by default" do
      {:ok, pending1} =
        PendingChanges.create_pending_change(%{
          change_type: "create_school",
          payload: %{"school_name" => "Test1"},
          submitted_by_ip: "127.0.0.1"
        })

      {:ok, pending2} =
        PendingChanges.create_pending_change(%{
          change_type: "create_school",
          payload: %{"school_name" => "Test2"},
          submitted_by_ip: "127.0.0.1"
        })

      # Reject one
      PendingChanges.reject_change!(pending2)

      pending_list = PendingChanges.list_pending()

      assert length(pending_list) == 1
      assert hd(pending_list).id == pending1.id
    end

    test "filters by change_type" do
      {:ok, _school_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_school",
          payload: %{"school_name" => "Test"},
          submitted_by_ip: "127.0.0.1"
        })

      {:ok, period_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_period",
          payload: %{"starts_on" => "2026-01-01"},
          submitted_by_ip: "127.0.0.1"
        })

      period_list = PendingChanges.list_pending(change_type: "create_period")

      assert length(period_list) == 1
      assert hd(period_list).id == period_change.id
    end
  end

  describe "already processed changes" do
    test "approve_change! returns error for already approved change" do
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)
      county = insert(:county, parent_location_id: federal_state.id)
      city = insert(:city, parent_location_id: county.id)
      zip_code = insert(:zip_code, value: "99999")

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
            "school_name" => "Already Approved",
            "address_params" => %{
              "street" => "Test St 1",
              "zip_code" => "99999",
              "city" => "Berlin"
            },
            "city_id" => city.id,
            "zip_code" => "99999"
          },
          submitted_by_ip: "127.0.0.1"
        })

      # Approve first
      {:ok, _} = PendingChanges.approve_change!(pending_change)

      # Try to approve again
      updated = Repo.get!(PendingChange, pending_change.id)
      assert {:error, :already_processed} = PendingChanges.approve_change!(updated)
    end

    test "reject_change! returns error for already rejected change" do
      {:ok, pending_change} =
        PendingChanges.create_pending_change(%{
          change_type: "create_school",
          payload: %{"school_name" => "Test"},
          submitted_by_ip: "127.0.0.1"
        })

      # Reject once
      {:ok, _} = PendingChanges.reject_change!(pending_change)

      # Try to reject again
      updated = Repo.get!(PendingChange, pending_change.id)
      assert {:error, :already_processed} = PendingChanges.reject_change!(updated)
    end
  end
end
