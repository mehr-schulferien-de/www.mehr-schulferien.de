defmodule MehrSchulferien.PeriodsFederalStateLimitTest do
  use MehrSchulferien.DataCase
  import MehrSchulferien.Factory

  alias MehrSchulferien.Periods
  alias MehrSchulferien.Periods.FederalStateFerientageLimit

  describe "school year calculation" do
    test "get_school_year_for_date/1 returns correct school year" do
      # August 2024 should be 2024/2025
      assert Periods.get_school_year_for_date(~D[2024-08-01]) == "2024/2025"
      assert Periods.get_school_year_for_date(~D[2024-12-25]) == "2024/2025"

      # July 2025 should still be 2024/2025
      assert Periods.get_school_year_for_date(~D[2025-07-31]) == "2024/2025"

      # August 2025 should be 2025/2026
      assert Periods.get_school_year_for_date(~D[2025-08-01]) == "2025/2026"
    end
  end

  describe "federal state limit validation" do
    setup do
      # Get or create beweglicher ferientag type
      beweglicher_type =
        case MehrSchulferien.Repo.get_by(MehrSchulferien.Calendars.HolidayOrVacationType,
               slug: "beweglicher-ferientag"
             ) do
          nil ->
            insert(:holiday_or_vacation_type,
              name: "Beweglicher Ferientag",
              slug: "beweglicher-ferientag"
            )

          existing ->
            existing
        end

      # Create location hierarchy
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id, name: "Test State")
      county = insert(:county, parent_location_id: federal_state.id)
      city = insert(:city, parent_location_id: county.id)
      school = insert(:school, parent_location_id: city.id)

      # Create limit for the federal state
      {:ok, limit} =
        %FederalStateFerientageLimit{}
        |> FederalStateFerientageLimit.changeset(%{
          federal_state_id: federal_state.id,
          school_year: "2024/2025",
          max_bewegliche_ferientage: 3
        })
        |> Repo.insert()

      %{
        school: school,
        federal_state: federal_state,
        limit: limit,
        beweglicher_type: beweglicher_type
      }
    end

    test "get_school_federal_state/1 returns the federal state for a school", %{
      school: school,
      federal_state: federal_state
    } do
      result = Periods.get_school_federal_state(school.id)
      assert result.id == federal_state.id
    end

    test "get_federal_state_ferientage_limit/2 returns the limit", %{
      federal_state: federal_state,
      limit: limit
    } do
      result = Periods.get_federal_state_ferientage_limit(federal_state.id, "2024/2025")
      assert result.id == limit.id
      assert result.max_bewegliche_ferientage == 3
    end

    test "count_bewegliche_ferientage_for_school_year/2 counts correctly", %{school: school} do
      # Initially should be 0
      assert Periods.count_bewegliche_ferientage_for_school_year(school.id, "2024/2025") == 0

      # Create some bewegliche Ferientage
      {:ok, _} =
        Periods.create_beweglicher_ferientag_for_school(school.id, ~D[2024-09-01], "Test 1")

      {:ok, _} =
        Periods.create_beweglicher_ferientag_for_school(school.id, ~D[2024-12-15], "Test 2")

      # Should now be 2
      assert Periods.count_bewegliche_ferientage_for_school_year(school.id, "2024/2025") == 2

      # Create one in different school year (should not be counted)
      {:ok, _} =
        Periods.create_beweglicher_ferientag_for_school(school.id, ~D[2025-09-01], "Test 3")

      # Should still be 2 for 2024/2025
      assert Periods.count_bewegliche_ferientage_for_school_year(school.id, "2024/2025") == 2
      assert Periods.count_bewegliche_ferientage_for_school_year(school.id, "2025/2026") == 1
    end

    test "validate_bewegliche_ferientage_limit/3 validates correctly", %{school: school} do
      # Should allow first 6 (3 * 2 with wiggle room)
      for i <- 1..6 do
        assert {:ok, _} =
                 Periods.validate_bewegliche_ferientage_limit(
                   school.id,
                   Date.add(~D[2024-09-01], (i - 1) * 30),
                   "Test #{i}"
                 )

        {:ok, _} =
          Periods.create_beweglicher_ferientag_for_school(
            school.id,
            Date.add(~D[2024-09-01], (i - 1) * 30),
            "Test #{i}"
          )
      end

      # Should reject 7th
      assert {:error, reason} =
               Periods.validate_bewegliche_ferientage_limit(school.id, ~D[2025-03-01], "Test 7")

      assert String.contains?(reason, "maximale Anzahl von 6")
    end

    test "create_beweglicher_ferientag_for_school/3 respects limit", %{school: school} do
      # Create 6 ferientage (the limit * 2 with wiggle room)
      for i <- 1..6 do
        {:ok, _} =
          Periods.create_beweglicher_ferientag_for_school(
            school.id,
            Date.add(~D[2024-09-01], (i - 1) * 30),
            "Test #{i}"
          )
      end

      # 7th should fail
      assert {:error, reason} =
               Periods.create_beweglicher_ferientag_for_school(
                 school.id,
                 ~D[2025-03-01],
                 "Test 7"
               )

      assert String.contains?(reason, "maximale Anzahl")
    end

    test "federal state with no limit allows unlimited ferientage", %{school: school} do
      # Delete the limit
      Repo.delete_all(FederalStateFerientageLimit)

      # Should allow many ferientage
      for i <- 1..10 do
        date = Date.add(~D[2024-09-01], i * 10)

        assert {:ok, _} =
                 Periods.create_beweglicher_ferientag_for_school(school.id, date, "Test #{i}")
      end
    end

    test "federal state with 0 limit prevents any ferientage", %{
      federal_state: federal_state,
      school: school
    } do
      # Update limit to 0
      Repo.update_all(
        from(l in FederalStateFerientageLimit, where: l.federal_state_id == ^federal_state.id),
        set: [max_bewegliche_ferientage: 0]
      )

      # Should not allow any
      assert {:error, reason} =
               Periods.create_beweglicher_ferientag_for_school(school.id, ~D[2024-09-01], "Test")

      assert String.contains?(reason, "maximale Anzahl von 0")
    end
  end
end
