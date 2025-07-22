defmodule MehrSchulferien.PeriodsCopyTest do
  use MehrSchulferien.DataCase
  import MehrSchulferien.Factory

  alias MehrSchulferien.Periods

  describe "copy_bewegliche_ferientage/2" do
    setup do
      # Create beweglicher ferientag type
      _beweglicher_type =
        insert(:holiday_or_vacation_type,
          name: "Beweglicher Ferientag",
          slug: "beweglicher-ferientag"
        )

      # Create schools
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)
      county = insert(:county, parent_location_id: federal_state.id)
      city = insert(:city, parent_location_id: county.id)

      source_school = insert(:school, name: "Source School", parent_location_id: city.id)
      target_school1 = insert(:school, name: "Target School 1", parent_location_id: city.id)
      target_school2 = insert(:school, name: "Target School 2", parent_location_id: city.id)

      # Create bewegliche ferientage for source school
      date1 = Date.utc_today() |> Date.add(10)
      date2 = Date.utc_today() |> Date.add(20)

      {:ok, ferientag1} =
        Periods.create_beweglicher_ferientag_for_school(
          source_school.id,
          date1,
          "Pädagogischer Tag"
        )

      {:ok, ferientag2} =
        Periods.create_beweglicher_ferientag_for_school(
          source_school.id,
          date2,
          "Lehrerfortbildung"
        )

      %{
        source_school: source_school,
        target_school1: target_school1,
        target_school2: target_school2,
        ferientag1: ferientag1,
        ferientag2: ferientag2,
        date1: date1,
        date2: date2
      }
    end

    test "copies all ferientage to target schools", context do
      %{
        source_school: source_school,
        target_school1: target_school1,
        target_school2: target_school2
      } = context

      results =
        Periods.copy_bewegliche_ferientage(
          source_school.id,
          [target_school1.id, target_school2.id]
        )

      # Check results structure
      assert is_map(results)
      assert Map.has_key?(results, target_school1.id)
      assert Map.has_key?(results, target_school2.id)

      # Check that both ferientage were copied to both schools
      target1_results = results[target_school1.id]
      assert length(target1_results) == 2

      assert Enum.all?(target1_results, fn
               {:success, _} -> true
               _ -> false
             end)

      target2_results = results[target_school2.id]
      assert length(target2_results) == 2

      assert Enum.all?(target2_results, fn
               {:success, _} -> true
               _ -> false
             end)

      # Verify ferientage exist in database
      target1_ferientage = Periods.list_bewegliche_ferientage_for_school(target_school1.id)
      assert length(target1_ferientage) == 2

      target2_ferientage = Periods.list_bewegliche_ferientage_for_school(target_school2.id)
      assert length(target2_ferientage) == 2
    end

    test "skips ferientage that already exist", context do
      %{
        source_school: source_school,
        target_school1: target_school1,
        date1: date1
      } = context

      # Create existing ferientag on same date
      {:ok, _existing} =
        Periods.create_beweglicher_ferientag_for_school(
          target_school1.id,
          date1,
          "Already exists"
        )

      results =
        Periods.copy_bewegliche_ferientage(
          source_school.id,
          [target_school1.id]
        )

      target_results = results[target_school1.id]
      assert length(target_results) == 2

      # One should be skipped, one should succeed
      statuses =
        Enum.map(target_results, fn
          {:skipped, _, _} -> :skipped
          {:success, _} -> :success
          _ -> :other
        end)

      assert :skipped in statuses
      assert :success in statuses

      # Should still have only 2 ferientage (1 existing + 1 new)
      ferientage = Periods.list_bewegliche_ferientage_for_school(target_school1.id)
      assert length(ferientage) == 2
    end

    test "handles empty source ferientage", context do
      # Create a school with no ferientage  
      empty_school =
        insert(:school, parent_location_id: context.target_school1.parent_location_id)

      results =
        Periods.copy_bewegliche_ferientage(
          empty_school.id,
          [context.target_school1.id]
        )

      assert results[context.target_school1.id] == []
    end

    test "bulk_copy_bewegliche_ferientage/2 wraps in transaction", context do
      %{
        source_school: source_school,
        target_school1: target_school1,
        target_school2: target_school2
      } = context

      {:ok, results} =
        Periods.bulk_copy_bewegliche_ferientage(
          source_school.id,
          [target_school1.id, target_school2.id]
        )

      assert is_map(results)
      assert Map.has_key?(results, target_school1.id)
      assert Map.has_key?(results, target_school2.id)
    end
  end
end
