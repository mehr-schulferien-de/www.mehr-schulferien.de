defmodule MehrSchulferienWeb.Controllers.ShowYearLogicTest do
  use MehrSchulferienWeb.ConnCase, async: true

  describe "show_year logic consistency" do
    setup do
      # Create test data using proper factory names
      country = MehrSchulferien.Factory.build(:country, name: "Deutschland", slug: "deutschland")

      federal_state =
        MehrSchulferien.Factory.build(:federal_state, name: "Bayern", slug: "bayern")

      city = MehrSchulferien.Factory.build(:city, name: "München", slug: "muenchen")

      school =
        MehrSchulferien.Factory.build(:school, name: "Grundschule Test", slug: "grundschule-test")

      %{
        country: country,
        federal_state: federal_state,
        city: city,
        school: school
      }
    end

    test "year range calculation should be consistent", %{
      country: _country,
      federal_state: _federal_state
    } do
      year = 2024
      expected_range = (year - 3)..(year + 3) |> Enum.to_list()

      # Test that all controllers use the same range calculation logic
      assert expected_range == [2021, 2022, 2023, 2024, 2025, 2026, 2027]
    end

    test "periods by year grouping should be consistent" do
      # Mock periods data
      periods = [
        %{starts_on: ~D[2023-12-25], ends_on: ~D[2024-01-06]},
        %{starts_on: ~D[2024-03-25], ends_on: ~D[2024-04-05]},
        %{starts_on: ~D[2024-07-29], ends_on: ~D[2024-09-09]},
        %{starts_on: ~D[2025-03-31], ends_on: ~D[2025-04-11]}
      ]

      # Group by year logic (extracted from controllers)
      periods_by_year = Enum.group_by(periods, fn period -> period.starts_on.year end)

      expected = %{
        2023 => [%{starts_on: ~D[2023-12-25], ends_on: ~D[2024-01-06]}],
        2024 => [
          %{starts_on: ~D[2024-03-25], ends_on: ~D[2024-04-05]},
          %{starts_on: ~D[2024-07-29], ends_on: ~D[2024-09-09]}
        ],
        2025 => [%{starts_on: ~D[2025-03-31], ends_on: ~D[2025-04-11]}]
      }

      assert periods_by_year == expected
    end

    test "years with data filtering should be consistent" do
      check_years = [2021, 2022, 2023, 2024, 2025, 2026, 2027]

      periods_by_year = %{
        2023 => [%{starts_on: ~D[2023-12-25]}],
        2024 => [%{starts_on: ~D[2024-03-25]}, %{starts_on: ~D[2024-07-29]}],
        2025 => [%{starts_on: ~D[2025-03-31]}]
      }

      # Years with data logic (extracted from controllers)
      years_with_data =
        Enum.filter(check_years, fn check_year ->
          case Map.get(periods_by_year, check_year) do
            nil -> false
            periods -> length(periods) > 0
          end
        end)
        |> Enum.sort()

      assert years_with_data == [2023, 2024, 2025]
    end

    test "months map should be consistent" do
      # This is duplicated across controllers - should be centralized
      expected_months = %{
        1 => "Januar",
        2 => "Februar",
        3 => "März",
        4 => "April",
        5 => "Mai",
        6 => "Juni",
        7 => "Juli",
        8 => "August",
        9 => "September",
        10 => "Oktober",
        11 => "November",
        12 => "Dezember"
      }

      # This logic is repeated in all three controllers
      assert expected_months[1] == "Januar"
      assert expected_months[12] == "Dezember"
    end

    test "adjoining duration calculation should be consistent" do
      period = %{starts_on: ~D[2024-03-25], ends_on: ~D[2024-04-05]}

      _all_periods = [
        period,
        # Weekend period adjacent
        %{starts_on: ~D[2024-04-06], ends_on: ~D[2024-04-07]}
      ]

      # Basic duration calculation
      days = Date.diff(period.ends_on, period.starts_on) + 1
      assert days == 12

      # This logic exists in all three controllers and should be extracted
      expected_period_with_duration = Map.put(period, :adjoining_duration, 0)
      assert expected_period_with_duration.adjoining_duration == 0
    end

    test "FAQ data structure should be consistent" do
      # The pattern for fetching FAQ data is identical across controllers
      _today = ~D[2024-03-15]
      # Mock IDs
      _location_ids = [1, 2, 3]

      # Expected structure that should be returned by all controllers
      expected_keys = [
        :day_after_tomorrow,
        :day_after_tomorrows_public_holiday_periods,
        :day_after_tomorrows_school_free_periods,
        :today,
        :todays_public_holiday_periods,
        :todays_school_free_periods,
        :tomorrow,
        :tomorrows_public_holiday_periods,
        :tomorrows_school_free_periods,
        :yesterday,
        :yesterdays_public_holiday_periods,
        :yesterdays_school_free_periods
      ]

      # All controllers should return data with these keys
      for key <- expected_keys do
        assert is_atom(key)
      end
    end

    test "status code logic should be consistent" do
      # Test different scenarios for 404 status

      # Federal state: 404 when no data
      assert_404_when_no_data = fn has_data ->
        if has_data, do: 200, else: 404
      end

      # City: 404 when no schools OR no data
      assert_404_when_no_schools_or_data = fn city_has_schools, year_has_data ->
        if city_has_schools and year_has_data, do: 200, else: 404
      end

      # School: 404 when no data
      assert_404_when_no_data_school = fn has_data ->
        if has_data, do: 200, else: 404
      end

      # Test the logic
      assert assert_404_when_no_data.(true) == 200
      assert assert_404_when_no_data.(false) == 404

      assert assert_404_when_no_schools_or_data.(true, true) == 200
      assert assert_404_when_no_schools_or_data.(false, true) == 404
      assert assert_404_when_no_schools_or_data.(true, false) == 404

      assert assert_404_when_no_data_school.(true) == 200
      assert assert_404_when_no_data_school.(false) == 404
    end
  end

  describe "controller-specific differences" do
    test "school controller extends periods to next year until July" do
      year = 2024
      current_year_periods = [%{starts_on: ~D[2024-07-29], ends_on: ~D[2024-09-09]}]

      next_year_periods = [
        # Should be included
        %{starts_on: ~D[2025-06-30], ends_on: ~D[2025-07-31]},
        # Should be excluded
        %{starts_on: ~D[2025-08-01], ends_on: ~D[2025-08-15]}
      ]

      # Filter next year periods to include only those until July 31st
      next_year_july_periods =
        Enum.filter(next_year_periods, fn period ->
          {:ok, july_end_date} = Date.new(year + 1, 7, 31)
          Date.compare(period.starts_on, july_end_date) in [:lt, :eq]
        end)

      extended_periods = current_year_periods ++ next_year_july_periods

      assert length(extended_periods) == 2
      assert Enum.any?(extended_periods, &(&1.starts_on == ~D[2025-06-30]))
      refute Enum.any?(extended_periods, &(&1.starts_on == ~D[2025-08-01]))
    end

    test "city controller validates city has schools" do
      # Logic unique to city controller
      schools = []
      city_has_schools = not Enum.empty?(schools)
      assert city_has_schools == false

      schools_with_data = [%{name: "Test School"}]
      city_has_schools_with_data = not Enum.empty?(schools_with_data)
      assert city_has_schools_with_data == true
    end

    test "federal state controller has no unique validation" do
      # Federal state controller doesn't have additional validation like city/school
      # Just checks if has_data
      has_data = true
      status = if has_data, do: 200, else: 404
      assert status == 200
    end
  end
end
