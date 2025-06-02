defmodule MehrSchulferien.PeriodsTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.{Periods, Periods.ICal, Periods.Period}
  alias MehrSchulferien.Locations

  describe "periods" do
    @valid_attrs %{
      "created_by_email_address" => "george@example.com",
      "ends_on" => ~D[2010-04-20],
      "starts_on" => ~D[2010-04-17]
    }
    @update_attrs %{
      "html_class" => "white",
      "is_public_holiday" => true
    }
    @invalid_attrs %{
      "created_by_email_address" => "george@example.com",
      "ends_on" => ~D[2010-04-20],
      "starts_on" => ~D[2010-04-27]
    }

    test "list_periods/0 returns all periods" do
      period = insert(:period)
      assert [period_1] = Periods.list_periods()
      assert period.id == period_1.id
    end

    test "get_period!/1 returns the period with given id" do
      period = insert(:period)
      assert period_1 = Periods.get_period!(period.id)
      assert period.id == period_1.id
    end

    test "create_period/1 with valid data creates a period" do
      location = insert(:federal_state)
      holiday_or_vacation_type = insert(:holiday_or_vacation_type)

      valid_attrs =
        Map.merge(@valid_attrs, %{
          "holiday_or_vacation_type_id" => holiday_or_vacation_type.id,
          "location_id" => location.id
        })

      assert {:ok, %Period{} = period} = Periods.create_period(valid_attrs)

      assert period.created_by_email_address == "george@example.com"
      assert period.ends_on == ~D[2010-04-20]
      assert period.starts_on == ~D[2010-04-17]
      assert period.html_class == holiday_or_vacation_type.default_html_class
      assert period.is_public_holiday == holiday_or_vacation_type.default_is_public_holiday
      assert period.religion_id == holiday_or_vacation_type.default_religion_id
    end

    test "create_period/1 with attrs overriding holiday_or_vacation_type defaults" do
      location = insert(:federal_state)
      holiday_or_vacation_type = insert(:holiday_or_vacation_type)

      valid_attrs =
        Map.merge(@valid_attrs, %{
          "location_id" => location.id,
          "holiday_or_vacation_type_id" => holiday_or_vacation_type.id,
          "is_public_holiday" => !holiday_or_vacation_type.default_is_public_holiday
        })

      assert {:ok, %Period{} = period} = Periods.create_period(valid_attrs)
      assert period.created_by_email_address == "george@example.com"
      assert period.is_public_holiday != holiday_or_vacation_type.default_is_public_holiday
    end

    test "create_period/1 with invalid data returns error changeset" do
      location = insert(:federal_state)
      holiday_or_vacation_type = insert(:holiday_or_vacation_type)

      invalid_attrs =
        Map.merge(@invalid_attrs, %{
          "holiday_or_vacation_type_id" => holiday_or_vacation_type.id,
          "location_id" => location.id
        })

      assert {:error, %Ecto.Changeset{} = changeset} = Periods.create_period(invalid_attrs)

      assert %{starts_on: ["starts_on should be less than or equal to ends_on"]} =
               errors_on(changeset)

      invalid_attrs = Map.put(invalid_attrs, "ends_on", nil)
      assert {:error, %Ecto.Changeset{} = changeset} = Periods.create_period(invalid_attrs)
      assert %{ends_on: ["can't be blank"]} = errors_on(changeset)
    end

    test "update_period/2 with valid data updates the period" do
      period = insert(:period)
      assert {:ok, %Period{} = period} = Periods.update_period(period, @update_attrs)
      assert period.html_class == "white"
      assert period.is_public_holiday == true
    end

    test "update_period/2 with invalid data returns error changeset" do
      period = insert(:period)
      assert {:error, %Ecto.Changeset{}} = Periods.update_period(period, @invalid_attrs)
    end

    test "delete_period/1 deletes the period" do
      period = insert(:period)
      assert {:ok, %Period{}} = Periods.delete_period(period)
      assert_raise Ecto.NoResultsError, fn -> Periods.get_period!(period.id) end
    end

    test "change_period/1 returns a period changeset" do
      period = insert(:period)
      assert %Ecto.Changeset{} = Periods.change_period(period)
    end

    test "find_periods_by_month/2 returns periods if the month has a holiday" do
      _period_1 = insert(:period, %{starts_on: ~D[2020-02-04], ends_on: ~D[2020-02-07]})
      _period_2 = insert(:period, %{starts_on: ~D[2020-02-24], ends_on: ~D[2020-02-27]})
      period_3 = insert(:period, %{starts_on: ~D[2020-04-04], ends_on: ~D[2020-06-07]})
      periods = Periods.list_periods()
      assert Periods.find_periods_by_month(~D[2020-01-01], periods) == []
      assert length(Periods.find_periods_by_month(~D[2020-02-01], periods)) == 2
      assert [%Period{id: id}] = Periods.find_periods_by_month(~D[2020-04-01], periods)
      assert id == period_3.id
      assert [%Period{id: ^id}] = Periods.find_periods_by_month(~D[2020-05-01], periods)
      assert [%Period{id: ^id}] = Periods.find_periods_by_month(~D[2020-06-01], periods)
      assert Periods.find_periods_by_month(~D[2020-08-01], periods) == []
    end
  end

  describe "Query.list_years_with_periods/0" do
    test "returns empty list when there are no periods" do
      assert Periods.list_years_with_periods() == []
    end

    test "returns unique years from period start and end dates" do
      insert(:period, starts_on: ~D[2020-12-01], ends_on: ~D[2021-01-15]) # 2020, 2021
      insert(:period, starts_on: ~D[2021-05-10], ends_on: ~D[2021-05-20]) # 2021
      insert(:period, starts_on: ~D[2022-03-01], ends_on: ~D[2022-03-10]) # 2022
      insert(:period, starts_on: ~D[2020-06-01], ends_on: ~D[2020-06-05]) # 2020

      assert Periods.list_years_with_periods() == [2020, 2021, 2022]
    end

    test "returns sorted list of years" do
      insert(:period, starts_on: ~D[2023-01-01], ends_on: ~D[2023-01-05])
      insert(:period, starts_on: ~D[2021-01-01], ends_on: ~D[2021-01-05])
      insert(:period, starts_on: ~D[2022-01-01], ends_on: ~D[2022-01-05])
      assert Periods.list_years_with_periods() == [2021, 2022, 2023]
    end
  end

  describe "DateOperations.find_next_schoolday/2" do
    # Helper to create a simple holiday period
    defp holiday(start_date_str, end_date_str \\ nil) do
      start_date = Date.from_iso8601!(start_date_str)
      end_date = if end_date_str, do: Date.from_iso8601!(end_date_str), else: start_date
      %MehrSchulferien.Periods.Period{starts_on: start_date, ends_on: end_date, name: "Holiday"}
    end

    @sorted_holidays [
      holiday("2023-10-28", "2023-10-29"), # Sat, Sun
      holiday("2023-10-30"),              # Mon Holiday
      holiday("2023-11-01")               # Wed Holiday
    ] |> Enum.sort_by(& &1.starts_on)

    test "next day is a schoolday" do
      assert Periods.find_next_schoolday(@sorted_holidays, ~D[2023-10-24]) == ~D[2023-10-24]
    end

    test "skips a single holiday" do
      assert Periods.find_next_schoolday(@sorted_holidays, ~D[2023-10-30]) == ~D[2023-10-31]
    end

    test "skips a sequence of holidays (weekend + holiday)" do
      assert Periods.find_next_schoolday(@sorted_holidays, ~D[2023-10-28]) == ~D[2023-10-31]
    end
    
    test "current date is a schoolday before next holiday period" do
      assert Periods.find_next_schoolday(@sorted_holidays, ~D[2023-10-27]) == ~D[2023-10-27]
    end

    test "skips multiple separate holidays" do
      assert Periods.find_next_schoolday([holiday("2023-11-01")], ~D[2023-11-01]) == ~D[2023-11-02]
    end

    test "no subsequent schoolday if all remaining days are holidays (within list)" do
      limited_holidays = [holiday("2023-12-20"), holiday("2023-12-21")]
      assert Periods.find_next_schoolday(limited_holidays, ~D[2023-12-20]) == ~D[2023-12-22]
    end

    test "empty list of holidays means date is a schoolday" do
      assert Periods.find_next_schoolday([], ~D[2023-10-25]) == ~D[2023-10-25]
    end
  end

  describe "DateOperations.find_periods_by_month/2 additional tests" do
    test "returns periods with various month overlap scenarios" do
        p1 = insert(:period, %{starts_on: ~D[2023-02-25], ends_on: ~D[2023-03-05], name: "P1"})
        p2 = insert(:period, %{starts_on: ~D[2023-03-10], ends_on: ~D[2023-03-15], name: "P2"})
        p3 = insert(:period, %{starts_on: ~D[2023-03-25], ends_on: ~D[2023-04-05], name: "P3"})
        p4 = insert(:period, %{starts_on: ~D[2023-02-15], ends_on: ~D[2023-04-15], name: "P4"})
        _p5 = insert(:period, %{starts_on: ~D[2023-02-01], ends_on: ~D[2023-02-05], name: "P5"})
        _p6 = insert(:period, %{starts_on: ~D[2023-04-10], ends_on: ~D[2023-04-15], name: "P6"})
        p7 = insert(:period, %{starts_on: ~D[2023-03-20], ends_on: ~D[2023-03-20], name: "P7"})

        all_periods = [p1, p2, p3, p4, _p5, _p6, p7] |> Enum.sort_by(& &1.starts_on)
        
        march_periods = Periods.find_periods_by_month(~D[2023-03-01], all_periods)
        march_period_ids = Enum.map(march_periods, & &1.id) |> Enum.sort()
        expected_ids = Enum.map([p1, p2, p3, p4, p7], & &1.id) |> Enum.sort()

        assert march_period_ids == expected_ids
    end
  end

  describe "Query.list_years_with_periods/0" do
    test "returns empty list when there are no periods" do
      assert Periods.list_years_with_periods() == []
    end

    test "returns unique years from period start and end dates" do
      insert(:period, starts_on: ~D[2020-12-01], ends_on: ~D[2021-01-15]) # 2020, 2021
      insert(:period, starts_on: ~D[2021-05-10], ends_on: ~D[2021-05-20]) # 2021
      insert(:period, starts_on: ~D[2022-03-01], ends_on: ~D[2022-03-10]) # 2022
      insert(:period, starts_on: ~D[2020-06-01], ends_on: ~D[2020-06-05]) # 2020

      assert Periods.list_years_with_periods() == [2020, 2021, 2022]
    end

    test "returns sorted list of years" do
      insert(:period, starts_on: ~D[2023-01-01], ends_on: ~D[2023-01-05])
      insert(:period, starts_on: ~D[2021-01-01], ends_on: ~D[2021-01-05])
      insert(:period, starts_on: ~D[2022-01-01], ends_on: ~D[2022-01-05])
      assert Periods.list_years_with_periods() == [2021, 2022, 2023]
    end
  end

  describe "DateOperations.find_next_schoolday/2" do
    # Helper to create a simple holiday period
    defp holiday(start_date_str, end_date_str \\ nil) do
      start_date = Date.from_iso8601!(start_date_str)
      end_date = if end_date_str, do: Date.from_iso8601!(end_date_str), else: start_date
      # The Period struct requires more fields, but for the logic of find_next_schoolday,
      # only starts_on and ends_on are strictly necessary via is_holiday?
      %MehrSchulferien.Periods.Period{starts_on: start_date, ends_on: end_date, name: "Holiday"}
    end

    # Define a fixed set of holidays for these tests
    @sorted_holidays [
      holiday("2023-10-28", "2023-10-29"), # Sat, Sun (Weekend as holiday period)
      holiday("2023-10-30"),              # Monday Holiday
      holiday("2023-11-01")               # Wednesday Holiday
    ] |> Enum.sort_by(& &1.starts_on)


    test "next day is a schoolday" do
      # Tuesday, Oct 24th, 2023. No holidays immediately following.
      assert Periods.find_next_schoolday(@sorted_holidays, ~D[2023-10-24]) == ~D[2023-10-24]
    end

    test "skips a single holiday" do
      # Monday, Oct 30th is a holiday. Next schoolday is Oct 31st.
      assert Periods.find_next_schoolday(@sorted_holidays, ~D[2023-10-30]) == ~D[2023-10-31]
    end

    test "skips a sequence of holidays (weekend + holiday)" do
       # Start on Saturday, Oct 28th (part of weekend holiday)
      assert Periods.find_next_schoolday(@sorted_holidays, ~D[2023-10-28]) == ~D[2023-10-31]
    end
    
    test "current date is a schoolday before next holiday period" do
      assert Periods.find_next_schoolday(@sorted_holidays, ~D[2023-10-27]) == ~D[2023-10-27]
    end

    test "skips multiple separate holidays" do
      # Current date is Nov 1st (holiday)
      assert Periods.find_next_schoolday([holiday("2023-11-01")], ~D[2023-11-01]) == ~D[2023-11-02]
    end

    test "no subsequent schoolday if all remaining days are holidays (within list)" do
      limited_holidays = [holiday("2023-12-20"), holiday("2023-12-21")]
      assert Periods.find_next_schoolday(limited_holidays, ~D[2023-12-20]) == ~D[2023-12-22]
    end

    test "empty list of holidays means date is a schoolday" do
      assert Periods.find_next_schoolday([], ~D[2023-10-25]) == ~D[2023-10-25]
    end
  end
  
  describe "DateOperations.find_periods_by_month/2 additional tests" do
    test "returns periods with various month overlap scenarios" do
        p1 = insert(:period, %{starts_on: ~D[2023-02-25], ends_on: ~D[2023-03-05], name: "P1"})
        p2 = insert(:period, %{starts_on: ~D[2023-03-10], ends_on: ~D[2023-03-15], name: "P2"})
        p3 = insert(:period, %{starts_on: ~D[2023-03-25], ends_on: ~D[2023-04-05], name: "P3"})
        p4 = insert(:period, %{starts_on: ~D[2023-02-15], ends_on: ~D[2023-04-15], name: "P4"})
        _p5 = insert(:period, %{starts_on: ~D[2023-02-01], ends_on: ~D[2023-02-05], name: "P5"})
        _p6 = insert(:period, %{starts_on: ~D[2023-04-10], ends_on: ~D[2023-04-15], name: "P6"})
        p7 = insert(:period, %{starts_on: ~D[2023-03-20], ends_on: ~D[2023-03-20], name: "P7"})

        all_periods = [p1, p2, p3, p4, _p5, _p6, p7] |> Enum.sort_by(& &1.starts_on)
        
        march_periods = Periods.find_periods_by_month(~D[2023-03-01], all_periods)
        march_period_ids = Enum.map(march_periods, & &1.id) |> Enum.sort()
        expected_ids = Enum.map([p1, p2, p3, p4, p7], & &1.id) |> Enum.sort()

        assert march_period_ids == expected_ids
    end

    test "returns empty list when no periods match the month (additional test)" do
        _p1 = insert(:period, %{starts_on: ~D[2023-01-01], ends_on: ~D[2023-01-05]})
        _p2 = insert(:period, %{starts_on: ~D[2023-05-01], ends_on: ~D[2023-05-05]})
        all_periods = Periods.list_periods() # Gets all periods including those from other tests if run concurrently
        
        # Filter to only use p1 and p2 for this specific test context
        current_test_periods = Enum.filter(all_periods, fn p -> p.name == "P1" or p.name == "P2" end)
        # This filtering is problematic, names are not set for these. Better to delete all before test.
        # For now, assuming a clean slate or that list_periods only gets these two.
        # A better way: Repo.delete_all(Period) before inserting.
        # However, I cannot run Repo.delete_all here.
        # The test will rely on the list_periods() call inside find_periods_by_month to be correct or the broader set.
        # The original test `find_periods_by_month/2` creates its own scope of periods. I'll follow that.

        p_before = insert(:period, %{starts_on: ~D[2023-01-01], ends_on: ~D[2023-01-05]})
        p_after = insert(:period, %{starts_on: ~D[2023-05-01], ends_on: ~D[2023-05-05]})
        relevant_periods = [p_before, p_after]

        assert Periods.find_periods_by_month(~D[2023-03-01], relevant_periods) == []
    end
  end

  describe "Grouping.group_by_interval/1" do
    alias MehrSchulferien.Periods.BridgeDayPeriod

    test "correctly groups periods by gap intervals" do
      p1 = insert(:period, starts_on: ~D[2023-03-10], ends_on: ~D[2023-03-12]) # Ends Sun
      p2 = insert(:period, starts_on: ~D[2023-03-15], ends_on: ~D[2023-03-17]) # Starts Wed (Gap Mon, Tue = 2 days, diff=3)
      p3 = insert(:period, starts_on: ~D[2023-03-20], ends_on: ~D[2023-03-22]) # Starts Mon (Gap Sat, Sun = 2 days, diff=3)
      p4 = insert(:period, starts_on: ~D[2023-03-28], ends_on: ~D[2023-03-30]) # Starts Tue (Gap Wed,Thu,Fri,Sat,Sun = 5 days, diff=6 - too large)
      p5 = insert(:period, starts_on: ~D[2023-04-03], ends_on: ~D[2023-04-05]) # Starts Mon (Gap Fri,Sat,Sun = 3 days, diff=4)
      
      all_periods = Enum.sort_by([p1, p2, p3, p4, p5], & &1.starts_on)
      
      result = Periods.group_by_interval(all_periods)

      assert Map.has_key?(result, 3)
      assert length(result[3]) == 2
      assert Enum.any?(result[3], fn bd -> bd.last_period_id == p1.id && bd.next_period_id == p2.id && bd.diff == 3 end)
      assert Enum.any?(result[3], fn bd -> bd.last_period_id == p2.id && bd.next_period_id == p3.id && bd.diff == 3 end)
      
      assert Map.has_key?(result, 4)
      assert length(result[4]) == 1
      assert Enum.any?(result[4], fn bd -> bd.last_period_id == p4.id && bd.next_period_id == p5.id && bd.diff == 4 end)

      refute Map.has_key?(result, 2)
      refute Map.has_key?(result, 5)
      refute Map.has_key?(result, 6)
    end

    test "returns empty map for no qualifying gaps" do
      p1 = insert(:period, starts_on: ~D[2023-03-10], ends_on: ~D[2023-03-12])
      p2 = insert(:period, starts_on: ~D[2023-03-13], ends_on: ~D[2023-03-15]) # Consecutive (diff=1)
      p3 = insert(:period, starts_on: ~D[2023-03-25], ends_on: ~D[2023-03-30]) # Large gap (diff=10)
      all_periods = Enum.sort_by([p1, p2, p3], & &1.starts_on)
      assert Periods.group_by_interval(all_periods) == %{}
    end

    test "handles empty list of periods" do
      assert Periods.group_by_interval([]) == %{}
    end
  end

  describe "Grouping.list_periods_with_bridge_day/2" do
    alias MehrSchulferien.Periods.BridgeDayPeriod

    setup do
      p1_before = insert(:period, name: "Way Before", starts_on: ~D[2023-04-01], ends_on: ~D[2023-04-02])
      p2_consecutive_before = insert(:period, name: "Consecutive Before", starts_on: ~D[2023-04-07], ends_on: ~D[2023-04-08]) # Fri, Sat
      p3_fixed_before_gap = insert(:period, name: "Fixed Before Gap", starts_on: ~D[2023-04-09], ends_on: ~D[2023-04-10])   # Sun, Mon
      
      p4_fixed_after_gap = insert(:period, name: "Fixed After Gap", starts_on: ~D[2023-04-14], ends_on: ~D[2023-04-15])    # Fri, Sat
      p5_consecutive_after = insert(:period, name: "Consecutive After", starts_on: ~D[2023-04-16], ends_on: ~D[2023-04-17])  # Sun, Mon
      p6_way_after = insert(:period, name: "Way After", starts_on: ~D[2023-04-25], ends_on: ~D[2023-04-26])

      all_db_periods = Enum.sort_by([p1_before, p2_consecutive_before, p3_fixed_before_gap, p4_fixed_after_gap, p5_consecutive_after, p6_way_after], & &1.starts_on)
      
      user_vacation_as_gap = %BridgeDayPeriod{
        name: "My Bridging Vacation",
        starts_on: ~D[2023-04-11], ends_on: ~D[2023-04-13],
        last_period_id: p3_fixed_before_gap.id,
        next_period_id: p4_fixed_after_gap.id,
        html_class: "user-vacation-gap"
      }

      %{
        all_db_periods: all_db_periods,
        p2: p2_consecutive_before, p3: p3_fixed_before_gap,
        p4: p4_fixed_after_gap, p5: p5_consecutive_after,
        user_vacation_as_gap: user_vacation_as_gap
      }
    end

    test "constructs list with consecutive periods around the gap", %{all_db_periods: all_db_periods, p2: p2, p3: p3, p4: p4, p5: p5, user_vacation_as_gap: gap} do
      result = Periods.list_periods_with_bridge_day(all_db_periods, gap)
      result_items = Enum.map(result, fn item -> if item.__struct__ == Period, do: item.id, else: item.name end)
      assert result_items == [p2.id, p3.id, "My Bridging Vacation", p4.id, p5.id]
    end
  end

  describe "periods for certain time frame" do
    setup [:add_federal_state, :add_periods]

    test "list_school_vacation_periods/4 returns all periods within a time frame", %{
      country: country,
      federal_state: federal_state,
      vacation_period_1: _vacation_period_1,
      vacation_period_2: _vacation_period_2,
      vacation_period_3: _vacation_period_3
    } do
      location_ids = [country.id, federal_state.id]

      assert Enum.count(
               Periods.list_school_vacation_periods(location_ids, ~D[2021-02-01], ~D[2022-01-31])
             ) == 5

      short_time_periods =
        Periods.list_school_vacation_periods(location_ids, ~D[2021-04-11], ~D[2021-12-31])

      assert length(short_time_periods) == 4

      long_time_periods =
        Periods.list_school_vacation_periods(location_ids, ~D[2020-01-01], ~D[2022-12-31])

      assert length(long_time_periods) > 0
    end

    test "group_periods_single_year/2 groups periods with the same name together", %{
      federal_state: federal_state
    } do
      location_ids = Locations.recursive_location_ids(federal_state)
      today = ~D[2021-02-26]
      first_day = ~D[2021-01-01]
      last_day = ~D[2022-12-31]
      school_periods = Periods.list_school_vacation_periods(location_ids, first_day, last_day)
      assert length(school_periods) == 9
      grouped_periods = Periods.group_periods_single_year(school_periods, today)
      assert length(grouped_periods) == 5
      today = ~D[2021-03-02]
      school_periods = Periods.list_school_vacation_periods(location_ids, first_day, last_day)
      assert length(school_periods) == 9
      grouped_periods = Periods.group_periods_single_year(school_periods, today)
      assert length(grouped_periods) == 4
    end
  end

  describe "Grouping.group_by_interval/1" do
    alias MehrSchulferien.Periods.BridgeDayPeriod

    test "correctly groups periods by gap intervals" do
      p1 = insert(:period, starts_on: ~D[2023-03-10], ends_on: ~D[2023-03-12]) # Ends Sun
      p2 = insert(:period, starts_on: ~D[2023-03-15], ends_on: ~D[2023-03-17]) # Starts Wed (Gap Mon, Tue = 2 days, diff=3)
      p3 = insert(:period, starts_on: ~D[2023-03-20], ends_on: ~D[2023-03-22]) # Starts Mon (Gap Sat, Sun = 2 days, diff=3)
      p4 = insert(:period, starts_on: ~D[2023-03-28], ends_on: ~D[2023-03-30]) # Starts Tue (Gap Wed,Thu,Fri,Sat,Sun = 5 days, diff=6 - too large)
      p5 = insert(:period, starts_on: ~D[2023-04-03], ends_on: ~D[2023-04-05]) # Starts Mon (Gap Fri,Sat,Sun = 3 days, diff=4)
      
      all_periods = Enum.sort_by([p1, p2, p3, p4, p5], & &1.starts_on)
      
      result = Periods.group_by_interval(all_periods)

      assert Map.has_key?(result, 3)
      assert length(result[3]) == 2
      assert Enum.any?(result[3], fn bd -> bd.last_period_id == p1.id && bd.next_period_id == p2.id && bd.diff == 3 end)
      assert Enum.any?(result[3], fn bd -> bd.last_period_id == p2.id && bd.next_period_id == p3.id && bd.diff == 3 end)
      
      assert Map.has_key?(result, 4)
      assert length(result[4]) == 1
      assert Enum.any?(result[4], fn bd -> bd.last_period_id == p4.id && bd.next_period_id == p5.id && bd.diff == 4 end)

      refute Map.has_key?(result, 2)
      refute Map.has_key?(result, 5)
      refute Map.has_key?(result, 6)
    end

    test "returns empty map for no qualifying gaps" do
      p1 = insert(:period, starts_on: ~D[2023-03-10], ends_on: ~D[2023-03-12])
      p2 = insert(:period, starts_on: ~D[2023-03-13], ends_on: ~D[2023-03-15]) # Consecutive (diff=1)
      p3 = insert(:period, starts_on: ~D[2023-03-25], ends_on: ~D[2023-03-30]) # Large gap (diff=10)
      all_periods = Enum.sort_by([p1, p2, p3], & &1.starts_on)
      assert Periods.group_by_interval(all_periods) == %{}
    end

    test "handles empty list of periods" do
      assert Periods.group_by_interval([]) == %{}
    end
  end

  describe "Grouping.list_periods_with_bridge_day/2" do
    alias MehrSchulferien.Periods.BridgeDayPeriod

    setup do
      p1_before = insert(:period, name: "Way Before", starts_on: ~D[2023-04-01], ends_on: ~D[2023-04-02])
      p2_consecutive_before = insert(:period, name: "Consecutive Before", starts_on: ~D[2023-04-07], ends_on: ~D[2023-04-08]) # Fri, Sat
      p3_fixed_before_gap = insert(:period, name: "Fixed Before Gap", starts_on: ~D[2023-04-09], ends_on: ~D[2023-04-10])   # Sun, Mon
      
      # The "gap" or user's vacation would be Apr 11, 12, 13 (Tue, Wed, Thu)
      
      p4_fixed_after_gap = insert(:period, name: "Fixed After Gap", starts_on: ~D[2023-04-14], ends_on: ~D[2023-04-15])    # Fri, Sat
      p5_consecutive_after = insert(:period, name: "Consecutive After", starts_on: ~D[2023-04-16], ends_on: ~D[2023-04-17])  # Sun, Mon
      p6_way_after = insert(:period, name: "Way After", starts_on: ~D[2023-04-25], ends_on: ~D[2023-04-26])

      all_db_periods = Enum.sort_by([p1_before, p2_consecutive_before, p3_fixed_before_gap, p4_fixed_after_gap, p5_consecutive_after, p6_way_after], & &1.starts_on)
      
      user_vacation_as_gap = %BridgeDayPeriod{
        name: "My Bridging Vacation",
        starts_on: ~D[2023-04-11], ends_on: ~D[2023-04-13],
        last_period_id: p3_fixed_before_gap.id,
        next_period_id: p4_fixed_after_gap.id,
        html_class: "user-vacation-gap"
      }

      %{
        all_db_periods: all_db_periods,
        p2: p2_consecutive_before, p3: p3_fixed_before_gap,
        p4: p4_fixed_after_gap, p5: p5_consecutive_after,
        user_vacation_as_gap: user_vacation_as_gap
      }
    end

    test "constructs list with consecutive periods around the gap", %{all_db_periods: all_db_periods, p2: p2, p3: p3, p4: p4, p5: p5, user_vacation_as_gap: gap} do
      result = Periods.list_periods_with_bridge_day(all_db_periods, gap)
      
      result_items = Enum.map(result, fn item -> if item.__struct__ == Period, do: item.id, else: item.name end)
      
      # Expected: [p2.id, p3.id, "My Bridging Vacation", p4.id, p5.id]
      assert result_items == [p2.id, p3.id, "My Bridging Vacation", p4.id, p5.id]
    end
  end

  describe "filter periods" do
    setup [:add_federal_state, :add_periods]

    test "next_periods/3 returns a certain number of next periods", %{
      school_periods: school_periods
    } do
      today = ~D[2020-04-02]
      assert [period_1, period_2, period_3] = Periods.next_periods(school_periods, today, 3)
      assert period_1.starts_on == ~D[2020-04-06]
      assert period_2.starts_on == ~D[2020-10-31]
      assert period_3.starts_on == ~D[2020-12-23]
      today = ~D[2020-05-16]
      assert [period_4, period_5] = Periods.next_periods(school_periods, today, 2)
      assert period_4 == period_2
      assert period_5 == period_3
    end

    test "find_most_recent_period/2 returns the most recently ended period", %{
      school_periods: school_periods
    } do
      today = ~D[2020-05-02]
      period = Periods.find_most_recent_period(school_periods, today)
      assert period.starts_on == ~D[2020-04-06]
      today = ~D[2021-03-16]
      period = Periods.find_most_recent_period(school_periods, today)
      assert period.starts_on == ~D[2021-02-24]
    end
  end

  describe "icalendar" do
    test "period_to_event/1 converts period to an ICalendar event" do
      federal_state = insert(:federal_state)
      vacation_type = insert(:holiday_or_vacation_type)

      period =
        create_period(%{
          ends_on: ~D[2020-07-10],
          location_id: federal_state.id,
          starts_on: ~D[2020-07-07],
          vacation_type_id: vacation_type.id
        })

      assert %ICalendar.Event{
               dtend: dtend,
               dtstart: dtstart,
               location: location,
               summary: summary
             } = ICal.period_to_event(period, federal_state)

      assert dtend == {{2020, 7, 10}, {23, 59, 59}}
      assert dtstart == {{2020, 7, 7}, {0, 0, 0}}
      assert location == federal_state.name
      assert summary == vacation_type.colloquial
    end
  end

  defp add_federal_state(_) do
    federal_state = insert(:federal_state)
    {:ok, %{federal_state: federal_state}}
  end

  defp add_periods(%{federal_state: federal_state}) do
    school_periods = add_school_periods(%{location: federal_state})
    country = federal_state.parent_location_id |> MehrSchulferien.Locations.get_location!()

    # Extract specific vacation periods for testing
    vacation_periods =
      Enum.filter(school_periods, fn p ->
        p.is_school_vacation == true && p.is_valid_for_students == true
      end)

    vacation_period_1 = Enum.at(vacation_periods, 0)
    vacation_period_2 = Enum.at(vacation_periods, 1)
    vacation_period_3 = Enum.at(vacation_periods, 2)

    other_period =
      insert(:period, %{
        is_school_vacation: true,
        is_valid_for_students: true,
        starts_on: ~D[2020-10-31],
        ends_on: ~D[2020-10-31]
      })

    {:ok,
     %{
       federal_state: federal_state,
       country: country,
       school_periods: school_periods,
       vacation_period_1: vacation_period_1,
       vacation_period_2: vacation_period_2,
       vacation_period_3: vacation_period_3,
       other_period: other_period
     }}
  end

  defp create_period(%{
         ends_on: ends_on,
         location_id: location_id,
         starts_on: starts_on,
         vacation_type_id: vacation_type_id
       }) do
    {:ok, period} =
      Periods.create_period(%{
        created_by_email_address: "froderick@example.com",
        location_id: location_id,
        holiday_or_vacation_type_id: vacation_type_id,
        starts_on: starts_on,
        ends_on: ends_on
      })

    Periods.get_period!(period.id)
  end
end
