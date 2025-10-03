defmodule MehrSchulferien.PeriodsLimitTest do
  use MehrSchulferien.DataCase
  import MehrSchulferien.Factory

  alias MehrSchulferien.{Periods, Wiki, Config}

  # Helper function to find the next weekday from a given date
  defp find_next_weekday(date) do
    case Date.day_of_week(date) do
      6 -> Date.add(date, 2)
      7 -> Date.add(date, 1)
      _ -> date
    end
  end

  describe "copy_specific_bewegliche_ferientage/2 with daily limit" do
    setup do
      # Get or create beweglicher ferientag type
      _beweglicher_type =
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

      # Create schools
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)
      county = insert(:county, parent_location_id: federal_state.id)
      city = insert(:city, parent_location_id: county.id)

      source_school = insert(:school, name: "Source School", parent_location_id: city.id)
      target_school1 = insert(:school, name: "Target School 1", parent_location_id: city.id)
      target_school2 = insert(:school, name: "Target School 2", parent_location_id: city.id)

      # Create bewegliche ferientage for source school on weekdays only
      dates =
        for i <- 1..5 do
          Date.utc_today() |> Date.add(i * 10) |> find_next_weekday()
        end

      ferientage =
        Enum.map(dates, fn date ->
          {:ok, ft} =
            Periods.create_beweglicher_ferientag_for_school(
              source_school.id,
              date,
              "Test Ferientag"
            )

          ft
        end)

      %{
        source_school: source_school,
        target_school1: target_school1,
        target_school2: target_school2,
        ferientage: ferientage,
        dates: dates
      }
    end

    test "respects daily limit when copying", context do
      %{
        ferientage: ferientage,
        target_school1: target_school1,
        target_school2: target_school2
      } = context

      # Set up the daily count to be close to the limit
      today = Date.utc_today()
      limit = Config.daily_change_limit()

      # Manually set the count to be 2 less than the limit
      # (We already created 5 ferientage in setup)
      current_count = Wiki.get_daily_change_count(today)
      remaining = limit - current_count - 2

      # Increment to reach close to limit
      for _ <- 1..remaining do
        Wiki.increment_daily_change_count(today)
      end

      # Now we should have room for only 2 more changes
      results =
        Periods.copy_specific_bewegliche_ferientage(
          ferientage,
          [target_school1.id, target_school2.id]
        )

      # First school should get 2 successful copies, then hit limit
      target1_results = results[target_school1.id]

      successes =
        Enum.count(target1_results, fn
          {:success, _} -> true
          _ -> false
        end)

      limit_errors =
        Enum.count(target1_results, fn
          {:error, _, "Tageslimit erreicht"} -> true
          _ -> false
        end)

      assert successes == 2
      assert limit_errors == 3

      # Second school should get all limit errors
      target2_results = results[target_school2.id]

      assert Enum.all?(target2_results, fn
               {:error, _, "Tageslimit erreicht"} -> true
               _ -> false
             end)
    end

    test "tracks changes correctly", context do
      %{
        ferientage: [first_ft | _],
        target_school1: target_school1
      } = context

      today = Date.utc_today()
      count_before = Wiki.get_daily_change_count(today)

      # Copy just one ferientag
      Periods.copy_specific_bewegliche_ferientage(
        [first_ft],
        [target_school1.id]
      )

      count_after = Wiki.get_daily_change_count(today)

      # Should have incremented by 1
      assert count_after == count_before + 1
    end

    test "doesn't count skipped ferientage against limit", context do
      %{
        ferientage: ferientage,
        target_school1: target_school1,
        dates: [date1 | _]
      } = context

      # Create one ferientag that already exists
      {:ok, _} =
        Periods.create_beweglicher_ferientag_for_school(
          target_school1.id,
          date1,
          "Already exists"
        )

      today = Date.utc_today()
      count_before = Wiki.get_daily_change_count(today)

      results =
        Periods.copy_specific_bewegliche_ferientage(
          ferientage,
          [target_school1.id]
        )

      count_after = Wiki.get_daily_change_count(today)

      # Should have incremented by 4 (5 total - 1 skipped)
      assert count_after == count_before + 4

      # Check that one was skipped
      target_results = results[target_school1.id]

      skipped =
        Enum.count(target_results, fn
          {:skipped, _, _} -> true
          _ -> false
        end)

      assert skipped == 1
    end
  end

  describe "daily limit configuration" do
    test "daily limit is set to 250" do
      assert Config.daily_change_limit() == 250
    end
  end
end
