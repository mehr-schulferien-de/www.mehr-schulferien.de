defmodule MehrSchulferienWeb.BridgeDayTimelineComponentTest do
  use ExUnit.Case, async: true

  alias MehrSchulferienWeb.BridgeDayTimelineComponent

  defp render_timeline(assigns) do
    assigns
    |> BridgeDayTimelineComponent.bridge_day_timeline()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  test "uses correct singular grammar for one submitted vacation day" do
    html =
      render_timeline(%{
        bridge_day: %{starts_on: ~D[2026-05-15], ends_on: ~D[2026-05-15]},
        periods: [],
        reference_date: ~D[2026-01-01],
        vacation_days: 1,
        total_free_days: 4,
        efficiency_percentage: 300
      })

    assert html =~ "1 eingereichter Urlaubstag"
    refute html =~ "eingereichten Urlaubstag"
  end

  test "keeps plural wording for multiple submitted vacation days" do
    html =
      render_timeline(%{
        bridge_day: %{starts_on: ~D[2026-05-15], ends_on: ~D[2026-05-18]},
        periods: [],
        reference_date: ~D[2026-01-01],
        vacation_days: 2,
        total_free_days: 6,
        efficiency_percentage: 200
      })

    assert html =~ "2 eingereichte Urlaubstage"
  end

  test "abbreviates short leading months with a readable three-letter form" do
    # Window of 3 days before Jan 2nd shows only Dec 30-31: the label must be
    # "Dez." rather than the cryptic single letter "D."
    html =
      render_timeline(%{
        bridge_day: %{starts_on: ~D[2026-01-02], ends_on: ~D[2026-01-02]},
        periods: [],
        reference_date: ~D[2025-12-01],
        vacation_days: 1,
        total_free_days: 4,
        efficiency_percentage: 300,
        window_size: 3
      })

    assert html =~ "Dez."
    refute html =~ ~r/>\s*D\.\s*</
  end
end
