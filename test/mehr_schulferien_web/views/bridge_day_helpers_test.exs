defmodule MehrSchulferienWeb.BridgeDayHelpersTest do
  use MehrSchulferienWeb.ConnCase, async: true

  alias MehrSchulferienWeb.BridgeDayHelpers

  describe "format_month_header/2" do
    test "formats single month correctly" do
      start_date = ~D[2026-06-01]
      end_date = ~D[2026-06-10]

      assert BridgeDayHelpers.format_month_header(start_date, end_date) == "Juni"
    end

    test "formats multiple months in same year correctly" do
      start_date = ~D[2026-06-15]
      end_date = ~D[2026-07-15]

      assert BridgeDayHelpers.format_month_header(start_date, end_date) == "Jun. Juli"
    end

    test "formats multiple months in different years correctly" do
      start_date = ~D[2026-12-20]
      end_date = ~D[2027-01-05]

      assert BridgeDayHelpers.format_month_header(start_date, end_date) == "Dez. 2026 Januar 2027"
    end

    test "uses abbreviated first month when it has 3 or fewer days" do
      # June 28-30 to July
      start_date = ~D[2026-06-28]
      end_date = ~D[2026-07-05]

      assert BridgeDayHelpers.format_month_header(start_date, end_date) == "Jun. Juli"
    end

    test "includes years when abbreviated month spans different years" do
      # December 29-31 to January of next year
      start_date = ~D[2026-12-29]
      end_date = ~D[2027-01-05]

      assert BridgeDayHelpers.format_month_header(start_date, end_date) == "Dez. 2026 Januar 2027"
    end
  end
end
