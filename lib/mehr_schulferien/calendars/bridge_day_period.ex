defmodule MehrSchulferien.Calendars.BridgeDayPeriod do
  @moduledoc """
  Module to handle BridgeDayPeriod structs.

  BridgeDayPeriod structs are used instead of Period structs in certain
  functions.
  """

  alias MehrSchulferien.Calendars.HolidayOrVacationType

  defstruct display_priority: 20,
            ends_on: nil,
            holiday_or_vacation_type: %HolidayOrVacationType{name: "bridge_day"},
            html_class: "warning",
            is_public_holiday: false,
            is_school_vacation: false,
            last_period_id: nil,
            number_days: 0,
            starts_on: nil

  def create(last_period, next_period, date_diff) do
    ends_on = Date.add(next_period.starts_on, -1)
    starts_on = Date.add(last_period.ends_on, 1)
    number_days = date_diff - 1

    %__MODULE__{
      ends_on: ends_on,
      last_period_id: last_period.id,
      number_days: number_days,
      starts_on: starts_on
    }
  end
end
