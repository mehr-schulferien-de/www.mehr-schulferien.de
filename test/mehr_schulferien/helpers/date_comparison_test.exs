defmodule MehrSchulferien.Helpers.DateComparisonTest do
  use ExUnit.Case, async: true

  alias MehrSchulferien.Helpers.DateComparison

  describe "is_after?/2" do
    test "returns true when first date is after second date" do
      assert DateComparison.is_after?(~D[2024-01-02], ~D[2024-01-01])
      assert DateComparison.is_after?(~D[2024-02-01], ~D[2024-01-01])
    end

    test "returns false when first date is before second date" do
      refute DateComparison.is_after?(~D[2024-01-01], ~D[2024-01-02])
      refute DateComparison.is_after?(~D[2024-01-01], ~D[2024-02-01])
    end

    test "returns false when dates are equal" do
      refute DateComparison.is_after?(~D[2024-01-01], ~D[2024-01-01])
    end
  end

  describe "is_before?/2" do
    test "returns true when first date is before second date" do
      assert DateComparison.is_before?(~D[2024-01-01], ~D[2024-01-02])
      assert DateComparison.is_before?(~D[2024-01-01], ~D[2024-02-01])
    end

    test "returns false when first date is after second date" do
      refute DateComparison.is_before?(~D[2024-01-02], ~D[2024-01-01])
      refute DateComparison.is_before?(~D[2024-02-01], ~D[2024-01-01])
    end

    test "returns false when dates are equal" do
      refute DateComparison.is_before?(~D[2024-01-01], ~D[2024-01-01])
    end
  end

  describe "is_on_or_after?/2" do
    test "returns true when first date is after second date" do
      assert DateComparison.is_on_or_after?(~D[2024-01-02], ~D[2024-01-01])
    end

    test "returns true when dates are equal" do
      assert DateComparison.is_on_or_after?(~D[2024-01-01], ~D[2024-01-01])
    end

    test "returns false when first date is before second date" do
      refute DateComparison.is_on_or_after?(~D[2024-01-01], ~D[2024-01-02])
    end
  end

  describe "is_on_or_before?/2" do
    test "returns true when first date is before second date" do
      assert DateComparison.is_on_or_before?(~D[2024-01-01], ~D[2024-01-02])
    end

    test "returns true when dates are equal" do
      assert DateComparison.is_on_or_before?(~D[2024-01-01], ~D[2024-01-01])
    end

    test "returns false when first date is after second date" do
      refute DateComparison.is_on_or_before?(~D[2024-01-02], ~D[2024-01-01])
    end
  end

  describe "is_between?/3" do
    test "returns true when date is between start and end dates" do
      assert DateComparison.is_between?(~D[2024-01-15], ~D[2024-01-01], ~D[2024-01-31])
      assert DateComparison.is_between?(~D[2024-01-10], ~D[2024-01-01], ~D[2024-01-31])
    end

    test "returns true when date equals start date" do
      assert DateComparison.is_between?(~D[2024-01-01], ~D[2024-01-01], ~D[2024-01-31])
    end

    test "returns true when date equals end date" do
      assert DateComparison.is_between?(~D[2024-01-31], ~D[2024-01-01], ~D[2024-01-31])
    end

    test "returns false when date is before start date" do
      refute DateComparison.is_between?(~D[2023-12-31], ~D[2024-01-01], ~D[2024-01-31])
    end

    test "returns false when date is after end date" do
      refute DateComparison.is_between?(~D[2024-02-01], ~D[2024-01-01], ~D[2024-01-31])
    end
  end

  describe "ranges_overlap?/4" do
    test "returns true when ranges overlap" do
      # Partial overlap
      assert DateComparison.ranges_overlap?(
               ~D[2024-01-01],
               ~D[2024-01-15],
               ~D[2024-01-10],
               ~D[2024-01-20]
             )

      # First range contains second
      assert DateComparison.ranges_overlap?(
               ~D[2024-01-01],
               ~D[2024-01-31],
               ~D[2024-01-10],
               ~D[2024-01-20]
             )

      # Second range contains first
      assert DateComparison.ranges_overlap?(
               ~D[2024-01-10],
               ~D[2024-01-20],
               ~D[2024-01-01],
               ~D[2024-01-31]
             )
    end

    test "returns true when ranges touch at boundaries" do
      assert DateComparison.ranges_overlap?(
               ~D[2024-01-01],
               ~D[2024-01-10],
               ~D[2024-01-10],
               ~D[2024-01-20]
             )
    end

    test "returns false when ranges don't overlap" do
      refute DateComparison.ranges_overlap?(
               ~D[2024-01-01],
               ~D[2024-01-10],
               ~D[2024-01-11],
               ~D[2024-01-20]
             )

      refute DateComparison.ranges_overlap?(
               ~D[2024-01-11],
               ~D[2024-01-20],
               ~D[2024-01-01],
               ~D[2024-01-10]
             )
    end
  end

  describe "filter_after/3" do
    setup do
      periods = [
        %{starts_on: ~D[2024-01-01], name: "Period 1"},
        %{starts_on: ~D[2024-01-15], name: "Period 2"},
        %{starts_on: ~D[2024-02-01], name: "Period 3"}
      ]

      {:ok, periods: periods}
    end

    test "filters items after given date", %{periods: periods} do
      result = DateComparison.filter_after(periods, ~D[2024-01-10], & &1.starts_on)
      assert length(result) == 2
      assert Enum.map(result, & &1.name) == ["Period 2", "Period 3"]
    end

    test "excludes items on the same date", %{periods: periods} do
      result = DateComparison.filter_after(periods, ~D[2024-01-15], & &1.starts_on)
      assert length(result) == 1
      assert hd(result).name == "Period 3"
    end

    test "returns empty list when all items are before or on date", %{periods: periods} do
      result = DateComparison.filter_after(periods, ~D[2024-02-01], & &1.starts_on)
      assert result == []
    end
  end

  describe "filter_before/3" do
    setup do
      periods = [
        %{ends_on: ~D[2024-01-01], name: "Period 1"},
        %{ends_on: ~D[2024-01-15], name: "Period 2"},
        %{ends_on: ~D[2024-02-01], name: "Period 3"}
      ]

      {:ok, periods: periods}
    end

    test "filters items before given date", %{periods: periods} do
      result = DateComparison.filter_before(periods, ~D[2024-01-20], & &1.ends_on)
      assert length(result) == 2
      assert Enum.map(result, & &1.name) == ["Period 1", "Period 2"]
    end

    test "excludes items on the same date", %{periods: periods} do
      result = DateComparison.filter_before(periods, ~D[2024-01-15], & &1.ends_on)
      assert length(result) == 1
      assert hd(result).name == "Period 1"
    end
  end
end
