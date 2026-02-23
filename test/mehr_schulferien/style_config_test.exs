defmodule MehrSchulferien.StyleConfigTest do
  use ExUnit.Case, async: true

  alias MehrSchulferien.StyleConfig

  describe "day_types/0" do
    test "returns all day type definitions with German names" do
      result = StyleConfig.day_types()

      assert result == %{
               holiday: "Feiertage",
               vacation: "Schulferien",
               weekend: "Wochenenden",
               bridge_day: "Brückentage"
             }
    end
  end

  describe "tailwind_classes/0" do
    test "returns mapping of day types to Tailwind CSS classes" do
      result = StyleConfig.tailwind_classes()

      assert is_map(result)
      assert Map.has_key?(result, :holiday)
      assert Map.has_key?(result, :vacation)
      assert Map.has_key?(result, :weekend)
      assert Map.has_key?(result, :bridge_day)

      # Verify the values are strings (CSS classes)
      Enum.each(result, fn {_key, value} ->
        assert is_binary(value)
      end)
    end
  end

  describe "tailwind_light_classes/0" do
    test "returns mapping of day types to lighter Tailwind CSS classes" do
      result = StyleConfig.tailwind_light_classes()

      assert is_map(result)
      assert Map.has_key?(result, :holiday)
      assert Map.has_key?(result, :vacation)
      assert Map.has_key?(result, :weekend)
      assert Map.has_key?(result, :bridge_day)

      # Verify the values are strings (CSS classes)
      Enum.each(result, fn {_key, value} ->
        assert is_binary(value)
      end)
    end
  end

  describe "get_class/2" do
    test "returns normal CSS class for a day type" do
      # Test each day type
      [:holiday, :vacation, :weekend, :bridge_day]
      |> Enum.each(fn day_type ->
        class = StyleConfig.get_class(day_type)
        assert is_binary(class)
        assert class != ""
      end)
    end

    test "returns light CSS class when light flag is true" do
      # Test each day type with light flag
      [:holiday, :vacation, :weekend, :bridge_day]
      |> Enum.each(fn day_type ->
        light_class = StyleConfig.get_class(day_type, true)
        normal_class = StyleConfig.get_class(day_type, false)

        assert is_binary(light_class)
        assert light_class != ""
        # Light and normal classes should be different
        assert light_class != normal_class
      end)
    end

    test "returns empty string for unknown day type" do
      assert StyleConfig.get_class(:unknown) == ""
      assert StyleConfig.get_class(:unknown, true) == ""
    end

    test "defaults to normal class when light flag is false" do
      normal_class = StyleConfig.get_class(:vacation)
      explicit_normal = StyleConfig.get_class(:vacation, false)

      assert normal_class == explicit_normal
    end
  end

  # Note: html_class_to_day_type/1 was removed when migrating from Bootstrap to Tailwind
  # The system now uses period_to_day_type/1 to determine day types from period attributes

  describe "period_to_day_type/1" do
    test "identifies vacation periods" do
      period = %{
        is_school_vacation: true,
        is_public_holiday: false,
        html_class: "success"
      }

      assert StyleConfig.period_to_day_type(period) == :vacation
    end

    test "identifies holiday periods" do
      period = %{
        is_school_vacation: false,
        is_public_holiday: true,
        html_class: "danger"
      }

      assert StyleConfig.period_to_day_type(period) == :holiday
    end

    # Note: Bridge days are identified by being a BridgeDayPeriod struct
    # Weekends are not stored as periods but determined by date

    test "returns nil for periods with no matching type" do
      period = %{
        is_school_vacation: false,
        is_public_holiday: false
      }

      assert StyleConfig.period_to_day_type(period) == nil
    end

    test "prioritizes vacation over other types" do
      # If both vacation and holiday are true, vacation takes precedence
      period = %{
        is_school_vacation: true,
        is_public_holiday: true,
        html_class: "danger"
      }

      assert StyleConfig.period_to_day_type(period) == :vacation
    end

    test "prioritizes holiday over html_class types" do
      # If holiday is true but html_class suggests bridge_day, holiday takes precedence
      period = %{
        is_school_vacation: false,
        is_public_holiday: true,
        html_class: "warning"
      }

      assert StyleConfig.period_to_day_type(period) == :holiday
    end

    test "handles periods with missing keys" do
      # Period without is_school_vacation key
      period = %{
        is_public_holiday: false,
        html_class: "primary"
      }

      assert StyleConfig.period_to_day_type(period) == nil
    end

    test "handles empty map" do
      assert StyleConfig.period_to_day_type(%{}) == nil
    end
  end

  describe "type consistency" do
    test "all functions return expected types" do
      # Verify type specs are adhered to
      assert is_map(StyleConfig.day_types())
      assert is_map(StyleConfig.tailwind_classes())
      assert is_map(StyleConfig.tailwind_light_classes())

      assert is_binary(StyleConfig.get_class(:vacation))

      # html_class_to_day_type was removed - using period_to_day_type instead
      period = %{is_school_vacation: true}

      result = StyleConfig.period_to_day_type(period)
      assert is_atom(result)

      result2 = StyleConfig.period_to_day_type(%{is_school_vacation: true})
      assert is_atom(result2)
    end
  end
end
