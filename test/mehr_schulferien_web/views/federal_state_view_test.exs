defmodule MehrSchulferienWeb.FederalStateViewTest do
  use MehrSchulferienWeb.ConnCase, async: true

  alias MehrSchulferienWeb.FederalStateView

  describe "calculate_effective_duration/2" do
    test "correctly calculates the effective duration including adjacent days off" do
      # Test case based on Pfingstferien 2025 in Bayern

      # Create test periods
      pfingstmontag = %{
        starts_on: ~D[2025-06-09],
        ends_on: ~D[2025-06-09],
        holiday_or_vacation_type: %{name: "Pfingstmontag", colloquial: "Pfingstmontag"}
      }

      pfingstferien = %{
        starts_on: ~D[2025-06-10],
        ends_on: ~D[2025-06-20],
        holiday_or_vacation_type: %{name: "Pfingsten", colloquial: "Pfingstferien"}
      }

      fronleichnam = %{
        starts_on: ~D[2025-06-19],
        ends_on: ~D[2025-06-19],
        holiday_or_vacation_type: %{name: "Fronleichnam", colloquial: "Fronleichnam"}
      }

      # All periods
      periods = [pfingstmontag, pfingstferien, fronleichnam]

      # Calculate effective duration of Pfingstferien
      effective_duration = FederalStateView.calculate_effective_duration(pfingstferien, periods)

      # Base duration calculation (10-20 June = 11 days)
      base_duration = Date.diff(pfingstferien.ends_on, pfingstferien.starts_on) + 1
      assert base_duration == 11

      # Expected total:
      # - Base 11 days (10-20 June)
      # - Plus 3 days before: Pfingstmontag (9 June) and weekend (7-8 June)
      # - Plus 2 days after: weekend (21-22 June)
      # Total: 16 days
      assert effective_duration == 16
    end
  end
end
