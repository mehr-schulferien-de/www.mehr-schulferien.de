defmodule MehrSchulferien.BridgeDayCalculationsTest do
  use ExUnit.Case, async: true

  alias MehrSchulferien.BridgeDayCalculations

  describe "get_number_max_days/1" do
    test "calculates correct number of days for single period" do
      periods = [
        %{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05]}
      ]

      assert BridgeDayCalculations.get_number_max_days(periods) == 5
    end

    test "calculates correct number of days for multiple periods" do
      periods = [
        %{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-03]},
        %{starts_on: ~D[2024-01-04], ends_on: ~D[2024-01-05]},
        %{starts_on: ~D[2024-01-06], ends_on: ~D[2024-01-10]}
      ]

      # From Jan 1 to Jan 10 = 10 days
      assert BridgeDayCalculations.get_number_max_days(periods) == 10
    end

    test "handles single day period" do
      periods = [
        %{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-01]}
      ]

      assert BridgeDayCalculations.get_number_max_days(periods) == 1
    end

    test "returns 0 for empty list" do
      assert BridgeDayCalculations.get_number_max_days([]) == 0
    end
  end

  describe "meets_minimum_gain?/2" do
    test "1 vacation day requires at least 3 free days" do
      bridge_day = %{number_days: 1}

      # 3 free days - meets minimum
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-03]}]
      assert BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)

      # 2 free days - doesn't meet minimum
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-02]}]
      refute BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)
    end

    test "2 vacation days requires at least 4 free days" do
      bridge_day = %{number_days: 2}

      # 4 free days - meets minimum
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-04]}]
      assert BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)

      # 3 free days - doesn't meet minimum
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-03]}]
      refute BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)
    end

    test "3 vacation days requires at least 5 free days" do
      bridge_day = %{number_days: 3}

      # 5 free days - meets minimum
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05]}]
      assert BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)

      # 4 free days - doesn't meet minimum
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-04]}]
      refute BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)
    end

    test "4 vacation days requires at least 6 free days" do
      bridge_day = %{number_days: 4}

      # 6 free days - meets minimum
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-06]}]
      assert BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)

      # 5 free days - doesn't meet minimum
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05]}]
      refute BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)
    end

    test "fallback rule: vacation days + 2 for other values" do
      bridge_day = %{number_days: 7}

      # 9 free days (7 + 2) - meets minimum
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-09]}]
      assert BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)

      # 8 free days - doesn't meet minimum
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-08]}]
      refute BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)
    end
  end
end
