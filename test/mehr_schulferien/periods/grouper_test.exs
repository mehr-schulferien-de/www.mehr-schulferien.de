defmodule MehrSchulferien.Periods.GrouperTest do
  use MehrSchulferien.DataCase

  alias MehrSchulferien.Periods.Grouper

  describe "group_consecutive_periods/1" do
    test "groups two consecutive Bewegliche Ferientage with same memo" do
      periods = [
        %{
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag"},
          starts_on: ~D[2026-03-18],
          ends_on: ~D[2026-03-18],
          memo: "Mündliches Abitur (unterrichtsfrei)"
        },
        %{
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag"},
          starts_on: ~D[2026-03-19],
          ends_on: ~D[2026-03-19],
          memo: "Mündliches Abitur (unterrichtsfrei)"
        }
      ]

      result = Grouper.group_consecutive_periods(periods)

      assert length(result) == 1
      assert hd(result).starts_on == ~D[2026-03-18]
      assert hd(result).ends_on == ~D[2026-03-19]
      assert hd(result).memo == "Mündliches Abitur (unterrichtsfrei)"
    end

    test "groups multiple consecutive Bewegliche Ferientage" do
      periods = [
        %{
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag"},
          starts_on: ~D[2026-02-16],
          ends_on: ~D[2026-02-16],
          memo: "Faschingsferien"
        },
        %{
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag"},
          starts_on: ~D[2026-02-17],
          ends_on: ~D[2026-02-17],
          memo: "Faschingsferien"
        },
        %{
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag"},
          starts_on: ~D[2026-02-18],
          ends_on: ~D[2026-02-18],
          memo: "Faschingsferien"
        },
        %{
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag"},
          starts_on: ~D[2026-02-19],
          ends_on: ~D[2026-02-19],
          memo: "Faschingsferien"
        },
        %{
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag"},
          starts_on: ~D[2026-02-20],
          ends_on: ~D[2026-02-20],
          memo: "Faschingsferien"
        }
      ]

      result = Grouper.group_consecutive_periods(periods)

      assert length(result) == 1
      assert hd(result).starts_on == ~D[2026-02-16]
      assert hd(result).ends_on == ~D[2026-02-20]
      assert hd(result).memo == "Faschingsferien"
    end

    test "does not group Bewegliche Ferientage with different memos" do
      periods = [
        %{
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag"},
          starts_on: ~D[2026-02-16],
          ends_on: ~D[2026-02-16],
          memo: "Faschingsferien"
        },
        %{
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag"},
          starts_on: ~D[2026-02-17],
          ends_on: ~D[2026-02-17],
          memo: "Something else"
        }
      ]

      result = Grouper.group_consecutive_periods(periods)

      assert length(result) == 2
    end

    test "does not group non-consecutive Bewegliche Ferientage" do
      periods = [
        %{
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag"},
          starts_on: ~D[2026-02-16],
          ends_on: ~D[2026-02-16],
          memo: "Faschingsferien"
        },
        %{
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag"},
          starts_on: ~D[2026-02-20],
          ends_on: ~D[2026-02-20],
          memo: "Faschingsferien"
        }
      ]

      result = Grouper.group_consecutive_periods(periods)

      assert length(result) == 2
    end

    test "does not group different types of periods" do
      periods = [
        %{
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag"},
          starts_on: ~D[2026-02-16],
          ends_on: ~D[2026-02-16],
          memo: nil
        },
        %{
          holiday_or_vacation_type: %{name: "Sommerferien"},
          starts_on: ~D[2026-02-17],
          ends_on: ~D[2026-02-17],
          memo: nil
        }
      ]

      result = Grouper.group_consecutive_periods(periods)

      assert length(result) == 2
    end

    test "handles empty list" do
      assert Grouper.group_consecutive_periods([]) == []
    end

    test "handles single period" do
      period = %{
        holiday_or_vacation_type: %{name: "Beweglicher Ferientag"},
        starts_on: ~D[2026-02-16],
        ends_on: ~D[2026-02-16],
        memo: "Test"
      }

      result = Grouper.group_consecutive_periods([period])

      assert result == [period]
    end

    test "groups periods over weekend (up to 3 days apart)" do
      periods = [
        %{
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag"},
          # Friday
          starts_on: ~D[2026-02-13],
          ends_on: ~D[2026-02-13],
          memo: "Test"
        },
        %{
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag"},
          # Monday
          starts_on: ~D[2026-02-16],
          ends_on: ~D[2026-02-16],
          memo: "Test"
        }
      ]

      result = Grouper.group_consecutive_periods(periods)

      assert length(result) == 1
      assert hd(result).starts_on == ~D[2026-02-13]
      assert hd(result).ends_on == ~D[2026-02-16]
    end

    test "preserves other fields in the period" do
      periods = [
        %{
          id: 1,
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag", id: 10},
          starts_on: ~D[2026-02-16],
          ends_on: ~D[2026-02-16],
          memo: "Test",
          location_id: 123,
          some_other_field: "value"
        },
        %{
          id: 2,
          holiday_or_vacation_type: %{name: "Beweglicher Ferientag", id: 10},
          starts_on: ~D[2026-02-17],
          ends_on: ~D[2026-02-17],
          memo: "Test",
          location_id: 123,
          some_other_field: "value"
        }
      ]

      result = Grouper.group_consecutive_periods(periods)

      assert length(result) == 1
      merged = hd(result)
      # Keeps first period's id
      assert merged.id == 1
      assert merged.location_id == 123
      assert merged.some_other_field == "value"
      assert merged.holiday_or_vacation_type.id == 10
    end
  end
end
