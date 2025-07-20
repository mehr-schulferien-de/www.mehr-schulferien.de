defmodule MehrSchulferien.Periods.DateOperationsTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.Periods.DateOperations

  describe "find_all_periods/2" do
    test "returns empty list when no periods match the date" do
      periods = [
        build(:period, starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05]),
        build(:period, starts_on: ~D[2024-01-10], ends_on: ~D[2024-01-15])
      ]

      assert DateOperations.find_all_periods(periods, ~D[2024-01-07]) == []
    end

    test "returns periods that contain the date" do
      period1 = build(:period, starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-10])
      period2 = build(:period, starts_on: ~D[2024-01-05], ends_on: ~D[2024-01-15])
      period3 = build(:period, starts_on: ~D[2024-01-20], ends_on: ~D[2024-01-25])

      periods = [period1, period2, period3]

      result = DateOperations.find_all_periods(periods, ~D[2024-01-07])
      assert length(result) == 2
      assert period1 in result
      assert period2 in result
    end

    test "includes periods that start on the date" do
      period = build(:period, starts_on: ~D[2024-01-05], ends_on: ~D[2024-01-10])
      periods = [period]

      assert DateOperations.find_all_periods(periods, ~D[2024-01-05]) == [period]
    end

    test "includes periods that end on the date" do
      period = build(:period, starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05])
      periods = [period]

      assert DateOperations.find_all_periods(periods, ~D[2024-01-05]) == [period]
    end
  end

  describe "find_next_schoolday/2" do
    test "returns nil when periods list is empty" do
      assert DateOperations.find_next_schoolday([], ~D[2024-01-01]) == nil
    end

    test "returns the date when it's not a holiday" do
      period = build(:period, starts_on: ~D[2024-01-10], ends_on: ~D[2024-01-15])
      periods = [period]

      assert DateOperations.find_next_schoolday(periods, ~D[2024-01-05]) == ~D[2024-01-05]
    end

    test "returns the next day after holiday period ends" do
      period1 = build(:period, starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05])
      period2 = build(:period, starts_on: ~D[2024-01-10], ends_on: ~D[2024-01-15])
      periods = [period1, period2]

      assert DateOperations.find_next_schoolday(periods, ~D[2024-01-03]) == ~D[2024-01-06]
    end

    test "skips consecutive holiday periods" do
      period1 = build(:period, starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05])
      period2 = build(:period, starts_on: ~D[2024-01-06], ends_on: ~D[2024-01-10])
      period3 = build(:period, starts_on: ~D[2024-01-15], ends_on: ~D[2024-01-20])
      periods = [period1, period2, period3]

      assert DateOperations.find_next_schoolday(periods, ~D[2024-01-03]) == ~D[2024-01-11]
    end
  end

  describe "find_periods_by_month/2" do
    test "returns empty list when no periods provided" do
      assert DateOperations.find_periods_by_month(~D[2024-01-15], []) == []
    end

    test "returns periods that overlap with the given month" do
      # Period entirely in January
      period1 = build(:period, starts_on: ~D[2024-01-05], ends_on: ~D[2024-01-15])
      # Period starting in December, ending in January
      period2 = build(:period, starts_on: ~D[2023-12-20], ends_on: ~D[2024-01-10])
      # Period starting in January, ending in February
      period3 = build(:period, starts_on: ~D[2024-01-25], ends_on: ~D[2024-02-05])
      # Period entirely in February
      period4 = build(:period, starts_on: ~D[2024-02-10], ends_on: ~D[2024-02-20])
      # Period entirely in December
      period5 = build(:period, starts_on: ~D[2023-12-01], ends_on: ~D[2023-12-15])

      periods = [period5, period2, period1, period3, period4]

      result = DateOperations.find_periods_by_month(~D[2024-01-15], periods)
      assert length(result) == 3
      assert period1 in result
      assert period2 in result
      assert period3 in result
    end
  end

  describe "find_periods_for_date_range/3" do
    test "returns periods within the date range" do
      period1 = build(:period, starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05])
      period2 = build(:period, starts_on: ~D[2024-01-10], ends_on: ~D[2024-01-15])
      period3 = build(:period, starts_on: ~D[2024-01-20], ends_on: ~D[2024-01-25])
      period4 = build(:period, starts_on: ~D[2024-01-30], ends_on: ~D[2024-02-05])

      periods = [period1, period2, period3, period4]

      result = DateOperations.find_periods_for_date_range(periods, ~D[2024-01-08], ~D[2024-01-22])
      assert result == [period2, period3]
    end

    test "includes periods that partially overlap the range" do
      # Period ends after range start
      period1 = build(:period, starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-12])
      # Period starts before range end
      period2 = build(:period, starts_on: ~D[2024-01-18], ends_on: ~D[2024-01-25])

      periods = [period1, period2]

      result = DateOperations.find_periods_for_date_range(periods, ~D[2024-01-10], ~D[2024-01-20])
      assert result == [period1, period2]
    end

    test "returns empty list when no periods match" do
      period1 = build(:period, starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05])
      period2 = build(:period, starts_on: ~D[2024-01-20], ends_on: ~D[2024-01-25])

      periods = [period1, period2]

      result = DateOperations.find_periods_for_date_range(periods, ~D[2024-01-10], ~D[2024-01-15])
      assert result == []
    end
  end

  describe "next_periods/3" do
    test "returns the specified number of upcoming periods" do
      period1 = build(:period, starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05])
      period2 = build(:period, starts_on: ~D[2024-01-10], ends_on: ~D[2024-01-15])
      period3 = build(:period, starts_on: ~D[2024-01-20], ends_on: ~D[2024-01-25])
      period4 = build(:period, starts_on: ~D[2024-01-30], ends_on: ~D[2024-02-05])

      periods = [period1, period2, period3, period4]

      result = DateOperations.next_periods(periods, ~D[2024-01-06], 2)
      assert result == [period2, period3]
    end

    test "includes current period if it hasn't ended yet" do
      period1 = build(:period, starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-10])
      period2 = build(:period, starts_on: ~D[2024-01-15], ends_on: ~D[2024-01-20])

      periods = [period1, period2]

      result = DateOperations.next_periods(periods, ~D[2024-01-05], 2)
      assert result == [period1, period2]
    end

    test "returns empty list when all periods have ended" do
      period1 = build(:period, starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05])
      period2 = build(:period, starts_on: ~D[2024-01-10], ends_on: ~D[2024-01-15])

      periods = [period1, period2]

      result = DateOperations.next_periods(periods, ~D[2024-01-20], 2)
      assert result == []
    end
  end

  describe "find_most_recent_period/2" do
    test "returns the most recently ended period" do
      period1 = build(:period, starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05])
      period2 = build(:period, starts_on: ~D[2024-01-10], ends_on: ~D[2024-01-15])
      period3 = build(:period, starts_on: ~D[2024-01-20], ends_on: ~D[2024-01-25])

      # Mix up the order to test sorting
      periods = [period3, period1, period2]

      result = DateOperations.find_most_recent_period(periods, ~D[2024-01-18])
      assert result == period2
    end

    test "returns nil when no periods have ended yet" do
      period1 = build(:period, starts_on: ~D[2024-01-10], ends_on: ~D[2024-01-15])
      period2 = build(:period, starts_on: ~D[2024-01-20], ends_on: ~D[2024-01-25])

      periods = [period1, period2]

      result = DateOperations.find_most_recent_period(periods, ~D[2024-01-05])
      assert result == nil
    end

    test "excludes periods ending today" do
      period1 = build(:period, starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05])
      period2 = build(:period, starts_on: ~D[2024-01-10], ends_on: ~D[2024-01-15])

      periods = [period1, period2]

      result = DateOperations.find_most_recent_period(periods, ~D[2024-01-15])
      assert result == period1
    end
  end
end
