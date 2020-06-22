defmodule MehrSchulferienWeb.PeriodView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferien.Calendars.HolidayOrVacationType
  alias MehrSchulferien.Periods.Period

  @doc """
  Returns an abbreviated form of the period name.
  """
  def vacation_type_name(%Period{
        holiday_or_vacation_type: %HolidayOrVacationType{colloquial: "Corona-Schulschließung"}
      }) do
    "COVID-19"
  end

  def vacation_type_name(%Period{holiday_or_vacation_type: %HolidayOrVacationType{name: name}}) do
    name |> String.split("/") |> List.first()
  end

  def vacation_type_name(_), do: ""
end
