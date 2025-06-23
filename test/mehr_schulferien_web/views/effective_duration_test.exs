defmodule MehrSchulferienWeb.Views.EffectiveDurationTest do
  use MehrSchulferienWeb.ConnCase, async: true

  alias MehrSchulferienWeb.ViewHelpers

  describe "calculate_effective_duration" do
    test "ViewHelpers implementation works correctly" do
      period = %{starts_on: ~D[2024-03-25], ends_on: ~D[2024-04-05]}
      periods = [period]

      # Direct call to ViewHelpers implementation
      direct_duration = ViewHelpers.calculate_effective_duration(period, periods)

      # Should return at least the basic duration
      assert direct_duration >= Date.diff(period.ends_on, period.starts_on) + 1
    end

    test "ViewHelpers implementation works correctly for various scenarios" do
      # Test basic case
      period = %{starts_on: ~D[2024-03-25], ends_on: ~D[2024-03-29]}
      periods = [period]
      duration = ViewHelpers.calculate_effective_duration(period, periods)
      # At least the basic 5 days
      assert duration >= 5

      # Test with adjacent periods
      adjacent_period = %{starts_on: ~D[2024-03-30], ends_on: ~D[2024-03-31]}

      duration_with_adjacent =
        ViewHelpers.calculate_effective_duration(period, [period, adjacent_period])

      # Should be same or more
      assert duration_with_adjacent >= duration

      # Test single day
      single_day = %{starts_on: ~D[2024-05-01], ends_on: ~D[2024-05-01]}
      single_duration = ViewHelpers.calculate_effective_duration(single_day, [single_day])
      assert single_duration >= 1
    end
  end

  describe "algorithm consistency" do
    test "ViewHelpers algorithm works correctly with various scenarios" do
      # Test with various period configurations
      test_cases = [
        # Simple case
        {%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05]}, []},
        # With adjacent periods
        {%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05]},
         [%{starts_on: ~D[2024-01-06], ends_on: ~D[2024-01-07]}]},
        # Longer period
        {%{starts_on: ~D[2024-07-15], ends_on: ~D[2024-08-30]}, []}
      ]

      for {period, other_periods} <- test_cases do
        all_periods = [period | other_periods]
        result = ViewHelpers.calculate_effective_duration(period, all_periods)
        basic_duration = Date.diff(period.ends_on, period.starts_on) + 1

        # Result should be at least the basic duration
        assert result >= basic_duration,
               "Effective duration should be at least the basic duration for period #{inspect(period)}"
      end
    end
  end
end
