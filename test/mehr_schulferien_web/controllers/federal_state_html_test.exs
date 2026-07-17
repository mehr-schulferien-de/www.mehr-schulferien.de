defmodule MehrSchulferienWeb.FederalStateHTMLTest do
  use ExUnit.Case, async: true

  alias MehrSchulferienWeb.FederalStateHTML

  defp vacation_period(name, colloquial, starts_on, ends_on) do
    %{
      starts_on: starts_on,
      ends_on: ends_on,
      holiday_or_vacation_type: %{
        name: name,
        colloquial: colloquial,
        default_is_school_vacation: true
      }
    }
  end

  describe "dynamic_federal_state_description/4" do
    test "uses the colloquial vacation name during a running vacation" do
      period = vacation_period("Sommer", "Sommerferien", ~D[2026-07-04], ~D[2026-08-22])
      today = ~D[2026-07-17]

      description =
        FederalStateHTML.dynamic_federal_state_description("Brandenburg", 2026, [period], today)

      assert description =~ "Die Sommerferien in Brandenburg laufen noch 36 Tage!"
      refute description =~ "Sommer in Brandenburg laufen"
    end

    test "uses singular 'Tag' on the last day of a vacation" do
      period = vacation_period("Sommer", "Sommerferien", ~D[2026-07-04], ~D[2026-08-22])
      today = ~D[2026-08-21]

      description =
        FederalStateHTML.dynamic_federal_state_description("Brandenburg", 2026, [period], today)

      assert description =~ "Die Sommerferien in Brandenburg laufen noch 1 Tag!"
    end

    test "uses the colloquial vacation name for an upcoming vacation" do
      period = vacation_period("Herbst", "Herbstferien", ~D[2026-10-19], ~D[2026-10-31])
      today = ~D[2026-10-14]

      description =
        FederalStateHTML.dynamic_federal_state_description("Brandenburg", 2026, [period], today)

      assert description =~ "Nur noch 5 Tage bis zu den Herbstferien in Brandenburg!"
    end

    test "falls back to the type name when colloquial is nil" do
      period = vacation_period("Sommerferien", nil, ~D[2026-07-04], ~D[2026-08-22])
      today = ~D[2026-07-17]

      description =
        FederalStateHTML.dynamic_federal_state_description("Brandenburg", 2026, [period], today)

      assert description =~ "Die Sommerferien in Brandenburg laufen noch 36 Tage!"
    end

    test "lists colloquial vacation names in the summary when no vacation is near" do
      period = vacation_period("Sommer", "Sommerferien", ~D[2026-07-04], ~D[2026-08-22])
      today = ~D[2026-01-10]

      description =
        FederalStateHTML.dynamic_federal_state_description("Brandenburg", 2026, [period], today)

      assert description =~ "✓ Sommerferien (04.07.-22.08.)"
    end
  end
end
