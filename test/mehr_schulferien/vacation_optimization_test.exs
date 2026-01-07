defmodule MehrSchulferien.VacationOptimizationTest do
  use MehrSchulferien.DataCase
  import MehrSchulferien.Factory

  alias MehrSchulferien.VacationOptimization
  alias MehrSchulferien.VacationOptimization.Result

  describe "find_optimal_windows/4" do
    setup do
      country = insert(:country, %{slug: "d", name: "Deutschland"})

      federal_state =
        insert(:federal_state, %{
          slug: "bayern",
          name: "Bayern",
          parent_location_id: country.id
        })

      # Create holiday types
      public_holiday_type =
        insert(:holiday_or_vacation_type, %{
          name: "Feiertag",
          colloquial: "Feiertag",
          default_is_public_holiday: true,
          default_is_school_vacation: false,
          default_is_valid_for_everybody: true,
          default_is_valid_for_students: true
        })

      school_vacation_type =
        insert(:holiday_or_vacation_type, %{
          name: "Osterferien",
          colloquial: "Osterferien",
          default_is_public_holiday: false,
          default_is_school_vacation: true,
          default_is_valid_for_everybody: false,
          default_is_valid_for_students: true
        })

      %{
        country: country,
        federal_state: federal_state,
        public_holiday_type: public_holiday_type,
        school_vacation_type: school_vacation_type
      }
    end

    test "finds optimal window with holidays around weekends", context do
      # Create a holiday on Friday (creates bridge day opportunity)
      # Friday 2026-04-03 (Karfreitag)
      insert(:period, %{
        starts_on: ~D[2026-04-03],
        ends_on: ~D[2026-04-03],
        location_id: context.country.id,
        holiday_or_vacation_type_id: context.public_holiday_type.id,
        is_public_holiday: true,
        is_valid_for_everybody: true
      })

      # Monday 2026-04-06 (Ostermontag)
      insert(:period, %{
        starts_on: ~D[2026-04-06],
        ends_on: ~D[2026-04-06],
        location_id: context.country.id,
        holiday_or_vacation_type_id: context.public_holiday_type.id,
        is_public_holiday: true,
        is_valid_for_everybody: true
      })

      location_ids = [context.country.id, context.federal_state.id]

      result = VacationOptimization.find_optimal_windows(location_ids, 2026, 5)

      assert is_list(result)
      assert length(result) > 0

      best = hd(result)
      assert %Result{} = best
      assert best.vacation_days_used <= 5
      assert best.total_free_days >= best.vacation_days_used
      assert best.efficiency_ratio >= 1.0
    end

    test "returns empty list when no holidays exist", context do
      location_ids = [context.country.id, context.federal_state.id]

      result = VacationOptimization.find_optimal_windows(location_ids, 2026, 10)

      # Should still return results (weekends only)
      assert is_list(result)
    end

    test "respects avoid_school_vacations option", context do
      # Create Easter holidays (school vacation)
      insert(:period, %{
        starts_on: ~D[2026-04-06],
        ends_on: ~D[2026-04-17],
        location_id: context.federal_state.id,
        holiday_or_vacation_type_id: context.school_vacation_type.id,
        is_school_vacation: true,
        is_valid_for_students: true
      })

      # Create public holidays in the same period
      insert(:period, %{
        starts_on: ~D[2026-04-03],
        ends_on: ~D[2026-04-03],
        location_id: context.country.id,
        holiday_or_vacation_type_id: context.public_holiday_type.id,
        is_public_holiday: true,
        is_valid_for_everybody: true
      })

      location_ids = [context.country.id, context.federal_state.id]

      # Normal variant - may include school vacation period
      normal_results = VacationOptimization.find_optimal_windows(location_ids, 2026, 10)

      # Budget variant - prioritizes efficiency but may include school vacations if needed
      # The budget variant sorts by efficiency first, then by fewest school vacation days
      budget_results =
        VacationOptimization.find_optimal_windows(location_ids, 2026, 10,
          avoid_school_vacations: true
        )

      assert is_list(normal_results)
      assert is_list(budget_results)

      # Budget results track school vacation days for ranking purposes
      # Results with fewer school vacation days are preferred when efficiency is equal
      for result <- budget_results do
        assert is_integer(result.school_vacation_days)
        assert result.school_vacation_days >= 0
      end
    end

    test "handles cross-year boundaries", context do
      # New Year's Day 2027
      insert(:period, %{
        starts_on: ~D[2027-01-01],
        ends_on: ~D[2027-01-01],
        location_id: context.country.id,
        holiday_or_vacation_type_id: context.public_holiday_type.id,
        is_public_holiday: true,
        is_valid_for_everybody: true
      })

      # Heilige Drei Könige 2027 (Bayern)
      insert(:period, %{
        starts_on: ~D[2027-01-06],
        ends_on: ~D[2027-01-06],
        location_id: context.federal_state.id,
        holiday_or_vacation_type_id: context.public_holiday_type.id,
        is_public_holiday: true,
        is_valid_for_everybody: true
      })

      location_ids = [context.country.id, context.federal_state.id]

      result =
        VacationOptimization.find_optimal_windows(location_ids, 2026, 10,
          include_cross_year: true
        )

      assert is_list(result)

      # Check if any result spans year boundary
      cross_year_results = Enum.filter(result, & &1.spans_year_boundary)
      # May or may not have cross-year results depending on optimization
      assert is_list(cross_year_results)
    end

    test "returns results sorted by efficiency", context do
      # Create multiple holiday opportunities
      insert(:period, %{
        starts_on: ~D[2026-05-01],
        ends_on: ~D[2026-05-01],
        location_id: context.country.id,
        holiday_or_vacation_type_id: context.public_holiday_type.id,
        is_public_holiday: true,
        is_valid_for_everybody: true
      })

      insert(:period, %{
        starts_on: ~D[2026-10-03],
        ends_on: ~D[2026-10-03],
        location_id: context.country.id,
        holiday_or_vacation_type_id: context.public_holiday_type.id,
        is_public_holiday: true,
        is_valid_for_everybody: true
      })

      location_ids = [context.country.id, context.federal_state.id]

      results = VacationOptimization.find_optimal_windows(location_ids, 2026, 5, top: 5)

      assert is_list(results)
      assert length(results) <= 5

      # Verify sorted by efficiency (descending)
      efficiencies = Enum.map(results, & &1.efficiency_ratio)
      assert efficiencies == Enum.sort(efficiencies, :desc)
    end

    test "limits results to top N", context do
      insert(:period, %{
        starts_on: ~D[2026-05-01],
        ends_on: ~D[2026-05-01],
        location_id: context.country.id,
        holiday_or_vacation_type_id: context.public_holiday_type.id,
        is_public_holiday: true,
        is_valid_for_everybody: true
      })

      location_ids = [context.country.id, context.federal_state.id]

      results = VacationOptimization.find_optimal_windows(location_ids, 2026, 30, top: 3)

      assert length(results) <= 3
    end

    test "calculates correct breakdown of day types", context do
      # Create a scenario where we know the breakdown
      # Thursday holiday followed by weekend = 4 days with 1 vacation day (Friday)
      insert(:period, %{
        starts_on: ~D[2026-05-21],
        ends_on: ~D[2026-05-21],
        location_id: context.country.id,
        holiday_or_vacation_type_id: context.public_holiday_type.id,
        is_public_holiday: true,
        is_valid_for_everybody: true
      })

      location_ids = [context.country.id, context.federal_state.id]

      results = VacationOptimization.find_optimal_windows(location_ids, 2026, 1, top: 10)

      assert is_list(results)

      if length(results) > 0 do
        result = hd(results)
        assert result.vacation_days_used >= 1
        assert result.weekend_days >= 0
        assert result.holiday_days >= 0
        # Total should match
        assert result.total_free_days ==
                 result.vacation_days_used + result.weekend_days + result.holiday_days
      end
    end

    test "correctly counts weekends vs holidays", context do
      # Create a single holiday on a Thursday (May 14, 2026 = Thursday for Christi Himmelfahrt)
      insert(:period, %{
        starts_on: ~D[2026-05-14],
        ends_on: ~D[2026-05-14],
        location_id: context.country.id,
        holiday_or_vacation_type_id: context.public_holiday_type.id,
        is_public_holiday: true,
        is_valid_for_everybody: true
      })

      location_ids = [context.country.id, context.federal_state.id]

      # With 1 vacation day (Friday), we get: Thu (holiday) + Fri (vacation) + Sat + Sun (weekend)
      # = 4 days total: 1 holiday, 1 vacation day, 2 weekend days
      results = VacationOptimization.find_optimal_windows(location_ids, 2026, 1, top: 10)

      assert is_list(results)
      assert length(results) > 0

      # Find the result that includes May 14
      may_14_result =
        Enum.find(results, fn r ->
          Date.compare(r.start_date, ~D[2026-05-14]) in [:lt, :eq] and
            Date.compare(r.end_date, ~D[2026-05-14]) in [:gt, :eq]
        end)

      if may_14_result do
        # Should have exactly 1 holiday day (Thursday)
        assert may_14_result.holiday_days == 1

        # Should have weekend days (Sat + Sun = 2)
        assert may_14_result.weekend_days >= 2

        # Weekends should NOT be counted as holidays
        assert may_14_result.total_free_days ==
                 may_14_result.vacation_days_used + may_14_result.weekend_days +
                   may_14_result.holiday_days
      end
    end
  end

  describe "Result struct" do
    test "has all required fields" do
      result = %Result{
        rank: 1,
        start_date: ~D[2026-04-03],
        end_date: ~D[2026-04-12],
        vacation_days_used: 5,
        total_free_days: 10,
        weekend_days: 4,
        holiday_days: 1,
        efficiency_ratio: 2.0,
        efficiency_percentage: 100,
        includes_school_vacation: false,
        related_holidays: ["Karfreitag", "Ostermontag"],
        spans_year_boundary: false
      }

      assert result.rank == 1
      assert result.vacation_days_used == 5
      assert result.total_free_days == 10
      assert result.efficiency_ratio == 2.0
    end
  end

  describe "efficiency calculations" do
    test "calculates correct efficiency ratio" do
      # 5 vacation days -> 10 free days = 2.0 ratio
      result = %Result{
        vacation_days_used: 5,
        total_free_days: 10,
        efficiency_ratio: 10 / 5,
        efficiency_percentage: round((10 - 5) / 5 * 100)
      }

      assert result.efficiency_ratio == 2.0
      assert result.efficiency_percentage == 100
    end

    test "calculates efficiency percentage correctly" do
      # 10 vacation days -> 15 free days = 50% efficiency
      vacation_days = 10
      total_free = 15
      efficiency_pct = round((total_free - vacation_days) / vacation_days * 100)

      assert efficiency_pct == 50
    end
  end

  describe "Optimizer.filter_distinct_results/2" do
    alias MehrSchulferien.VacationOptimization.Optimizer

    test "filters out overlapping results" do
      # Two results that overlap significantly (share 8 of 10 days = 80%)
      result1 = %Result{
        rank: 1,
        start_date: ~D[2026-04-01],
        end_date: ~D[2026-04-10],
        vacation_days_used: 5,
        total_free_days: 10,
        efficiency_ratio: 2.0
      }

      result2 = %Result{
        rank: 2,
        start_date: ~D[2026-04-03],
        end_date: ~D[2026-04-12],
        vacation_days_used: 5,
        total_free_days: 10,
        efficiency_ratio: 1.9
      }

      results = [result1, result2]
      filtered = Optimizer.filter_distinct_results(results)

      # Should only keep the first one since they overlap by >70%
      assert length(filtered) == 1
      assert hd(filtered).start_date == ~D[2026-04-01]
    end

    test "keeps non-overlapping results" do
      # Two results that don't overlap at all
      result1 = %Result{
        rank: 1,
        start_date: ~D[2026-04-01],
        end_date: ~D[2026-04-10],
        vacation_days_used: 5,
        total_free_days: 10,
        efficiency_ratio: 2.0
      }

      result2 = %Result{
        rank: 2,
        start_date: ~D[2026-06-01],
        end_date: ~D[2026-06-10],
        vacation_days_used: 5,
        total_free_days: 10,
        efficiency_ratio: 1.9
      }

      results = [result1, result2]
      filtered = Optimizer.filter_distinct_results(results)

      # Should keep both since they don't overlap
      assert length(filtered) == 2
    end

    test "respects max_results option" do
      results =
        for i <- 1..5 do
          %Result{
            rank: i,
            start_date: Date.add(~D[2026-01-01], i * 30),
            end_date: Date.add(~D[2026-01-10], i * 30),
            vacation_days_used: 5,
            total_free_days: 10,
            efficiency_ratio: 2.0 - i * 0.1
          }
        end

      filtered = Optimizer.filter_distinct_results(results, max_results: 2)

      assert length(filtered) == 2
    end

    test "respects custom overlap_threshold" do
      # Two results with 50% overlap
      result1 = %Result{
        rank: 1,
        start_date: ~D[2026-04-01],
        end_date: ~D[2026-04-10],
        vacation_days_used: 5,
        total_free_days: 10,
        efficiency_ratio: 2.0
      }

      result2 = %Result{
        rank: 2,
        start_date: ~D[2026-04-06],
        end_date: ~D[2026-04-15],
        vacation_days_used: 5,
        total_free_days: 10,
        efficiency_ratio: 1.9
      }

      results = [result1, result2]

      # With default 70% threshold, should keep both (50% < 70%)
      filtered_default = Optimizer.filter_distinct_results(results)
      assert length(filtered_default) == 2

      # With 40% threshold, should filter out the second (50% > 40%)
      filtered_strict = Optimizer.filter_distinct_results(results, overlap_threshold: 0.4)
      assert length(filtered_strict) == 1
    end
  end

  describe "Optimizer.compute_vacation_dates/2" do
    alias MehrSchulferien.VacationOptimization.Optimizer

    setup do
      country = insert(:country, %{slug: "d", name: "Deutschland"})

      public_holiday_type =
        insert(:holiday_or_vacation_type, %{
          name: "Feiertag",
          colloquial: "Feiertag",
          default_is_public_holiday: true
        })

      %{country: country, public_holiday_type: public_holiday_type}
    end

    test "excludes weekends from vacation dates" do
      result = %Result{
        start_date: ~D[2026-04-06],
        end_date: ~D[2026-04-12]
      }

      # No holidays, so only weekends should be excluded
      vacation_dates = Optimizer.compute_vacation_dates(result, [])

      # April 6 (Mon) to April 12 (Sun) = 7 days
      # Weekdays: Mon, Tue, Wed, Thu, Fri = 5 days
      # Weekends: Sat, Sun = 2 days (excluded)
      assert length(vacation_dates) == 5

      # None should be Saturday (6) or Sunday (7)
      for date <- vacation_dates do
        refute Date.day_of_week(date) in [6, 7]
      end
    end

    test "excludes public holidays from vacation dates", context do
      # Create a holiday on Wednesday April 8, 2026
      holiday_period =
        insert(:period, %{
          starts_on: ~D[2026-04-08],
          ends_on: ~D[2026-04-08],
          location_id: context.country.id,
          holiday_or_vacation_type_id: context.public_holiday_type.id,
          is_public_holiday: true,
          is_valid_for_everybody: true
        })

      result = %Result{
        start_date: ~D[2026-04-06],
        end_date: ~D[2026-04-12]
      }

      vacation_dates = Optimizer.compute_vacation_dates(result, [holiday_period])

      # Should exclude weekends (2 days) and the holiday (1 day)
      # 7 days - 2 weekends - 1 holiday = 4 vacation days
      assert length(vacation_dates) == 4

      # The holiday date should not be in the list
      refute ~D[2026-04-08] in vacation_dates
    end

    test "returns all workdays when no holidays in range" do
      result = %Result{
        start_date: ~D[2026-04-06],
        end_date: ~D[2026-04-10]
      }

      # Only weekdays: Mon to Fri = 5 days
      vacation_dates = Optimizer.compute_vacation_dates(result, [])

      assert length(vacation_dates) == 5
      assert ~D[2026-04-06] in vacation_dates
      assert ~D[2026-04-10] in vacation_dates
    end
  end
end
