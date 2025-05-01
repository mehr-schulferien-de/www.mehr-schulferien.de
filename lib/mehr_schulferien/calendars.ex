defmodule MehrSchulferien.Calendars do
  @moduledoc """
  The Calendars context.

  This context manages holidays, vacation types, and religious information.
  """

  alias MehrSchulferien.Calendars.{
    ReligionOperations,
    HolidayOperations
  }

  # Religion operations
  defdelegate list_religions, to: ReligionOperations
  defdelegate get_religion!(id), to: ReligionOperations
  defdelegate create_religion(attrs \\ %{}), to: ReligionOperations
  defdelegate update_religion(religion, attrs), to: ReligionOperations
  defdelegate delete_religion(religion), to: ReligionOperations
  defdelegate change_religion(religion), to: ReligionOperations

  # Holiday operations
  defdelegate list_holiday_or_vacation_types, to: HolidayOperations
  defdelegate list_is_school_vacation_types(country), to: HolidayOperations
  defdelegate get_holiday_or_vacation_type!(id), to: HolidayOperations
  defdelegate get_holiday_or_vacation_type_by_name!(name), to: HolidayOperations
  defdelegate get_holiday_or_vacation_type_by_slug!(slug), to: HolidayOperations
  defdelegate create_holiday_or_vacation_type(attrs \\ %{}), to: HolidayOperations

  defdelegate update_holiday_or_vacation_type(holiday_or_vacation_type, attrs),
    to: HolidayOperations

  defdelegate delete_holiday_or_vacation_type(holiday_or_vacation_type), to: HolidayOperations
  defdelegate change_holiday_or_vacation_type(holiday_or_vacation_type), to: HolidayOperations
end
