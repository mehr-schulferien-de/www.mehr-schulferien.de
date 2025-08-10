defmodule MehrSchulferien.WikiRollbackTest do
  use MehrSchulferien.DataCase

  alias MehrSchulferien.{Wiki, Periods, Repo}
  import MehrSchulferien.Factory

  describe "rollback_to_version/3" do
    test "successfully rolls back period to a previous version" do
      # Create test data
      germany = insert(:country, name: "Deutschland")
      federal_state = insert(:federal_state, parent_location_id: germany.id, name: "Test State")
      vacation_type = insert(:holiday_or_vacation_type, name: "Test Vacation")

      # Create a period with future dates
      future_date = Date.utc_today() |> Date.add(30)

      period =
        insert(:period,
          starts_on: future_date,
          ends_on: future_date |> Date.add(10),
          location_id: federal_state.id,
          holiday_or_vacation_type_id: vacation_type.id,
          memo: "Original memo"
        )

      # Create first version
      {:ok, %{model: _period, version: version1}} =
        PaperTrail.update(
          Periods.Period.changeset(period, %{memo: "Version 1"}),
          meta: %{ip_address: "127.0.0.1"}
        )

      # Create second version  
      {:ok, %{model: _period, version: _version2}} =
        PaperTrail.update(
          Periods.Period.changeset(Repo.reload!(period), %{memo: "Version 2"}),
          meta: %{ip_address: "127.0.0.1"}
        )

      # Verify current state
      period = Repo.reload!(period)
      assert period.memo == "Version 2"

      # Rollback to version 1
      result = Wiki.rollback_to_version(period, Integer.to_string(version1.id), "127.0.0.1")

      # Check the result
      assert {:ok, %{model: rolled_back_period}} = result
      assert rolled_back_period.memo == "Version 1"

      # Verify in database
      period = Repo.reload!(period)
      assert period.memo == "Version 1"
    end

    test "returns error for invalid version id" do
      period = insert(:period)
      result = Wiki.rollback_to_version(period, "invalid", "127.0.0.1")
      assert {:error, :invalid_version_id} = result
    end

    test "returns error for non-existent version" do
      period = insert(:period)
      result = Wiki.rollback_to_version(period, "99999", "127.0.0.1")
      assert {:error, :version_not_found} = result
    end
  end
end
