defmodule MehrSchulferienWeb.MonthHeaderFormatTest do
  use MehrSchulferienWeb.ConnCase

  # Focus on testing the view function directly rather than through the UI
  # which would require more complex test setup
  describe "month header formatting" do
    test "formats short month spans correctly" do
      view = MehrSchulferienWeb.BridgeDayView

      # Test case: June 28-30 to July 5 (first month has 3 days)
      start_date = ~D[2026-06-28]
      end_date = ~D[2026-07-05]

      assert view.format_month_header(start_date, end_date) == "J. Juli"

      # Test case: December 29-31 to January 5 (cross year)
      start_date = ~D[2026-12-29]
      end_date = ~D[2027-01-05]

      assert view.format_month_header(start_date, end_date) == "D. 2026 Januar 2027"
    end
  end
end
