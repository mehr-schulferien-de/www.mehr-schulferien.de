defmodule MehrSchulferien.Helpers.DateConstantsTest do
  use ExUnit.Case, async: true

  alias MehrSchulferien.Helpers.DateConstants

  describe "constants" do
    test "days_per_year returns 365" do
      assert DateConstants.days_per_year() == 365
    end

    test "days_per_month returns 30" do
      assert DateConstants.days_per_month() == 30
    end

    test "months_per_year returns 12" do
      assert DateConstants.months_per_year() == 12
    end

    test "days_per_week returns 7" do
      assert DateConstants.days_per_week() == 7
    end
  end

  describe "days_from_months/1" do
    test "calculates days from months correctly" do
      assert DateConstants.days_from_months(1) == 30
      assert DateConstants.days_from_months(2) == 60
      assert DateConstants.days_from_months(6) == 180
      assert DateConstants.days_from_months(12) == 360
    end

    test "handles zero months" do
      assert DateConstants.days_from_months(0) == 0
    end

    test "handles negative months" do
      assert DateConstants.days_from_months(-1) == -30
    end
  end

  describe "days_from_years/1" do
    test "calculates days from years correctly" do
      assert DateConstants.days_from_years(1) == 365
      assert DateConstants.days_from_years(2) == 730
      assert DateConstants.days_from_years(10) == 3650
    end

    test "handles zero years" do
      assert DateConstants.days_from_years(0) == 0
    end

    test "handles negative years" do
      assert DateConstants.days_from_years(-1) == -365
    end
  end
end
