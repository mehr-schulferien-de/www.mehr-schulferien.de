defmodule MehrSchulferienWeb.Views.EffectiveDurationTest do
  use MehrSchulferienWeb.ConnCase, async: true

  alias MehrSchulferienWeb.{FederalStateView, CityView, SchoolView, ViewHelpers}

  describe "calculate_effective_duration" do
    test "all views delegate to ViewHelpers implementation" do
      period = %{starts_on: ~D[2024-03-25], ends_on: ~D[2024-04-05]}
      periods = [period]

      # All three views should return the same result and delegate to ViewHelpers
      federal_state_duration = FederalStateView.calculate_effective_duration(period, periods)
      city_duration = CityView.calculate_effective_duration(period, periods)
      school_duration = SchoolView.calculate_effective_duration(period, periods)
      direct_duration = ViewHelpers.calculate_effective_duration(period, periods)

      # All should return the same result
      assert federal_state_duration == direct_duration
      assert city_duration == direct_duration
      assert school_duration == direct_duration
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
    test "all three views use the same core algorithm" do
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

        federal_state_result = FederalStateView.calculate_effective_duration(period, all_periods)
        city_result = CityView.calculate_effective_duration(period, all_periods)
        school_result = SchoolView.calculate_effective_duration(period, all_periods)

        # All should return the same result
        assert federal_state_result == city_result,
               "Federal state and city views differ for period #{inspect(period)}"

        assert city_result == school_result,
               "City and school views differ for period #{inspect(period)}"
      end
    end
  end
end
