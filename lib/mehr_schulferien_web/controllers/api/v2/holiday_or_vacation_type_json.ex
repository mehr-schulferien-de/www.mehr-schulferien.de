defmodule MehrSchulferienWeb.Api.V2.HolidayOrVacationTypeJSON do
  def index(%{holiday_or_vacation_types: holiday_or_vacation_types}) do
    %{data: for(type <- holiday_or_vacation_types, do: data(type))}
  end

  def show(%{holiday_or_vacation_type: holiday_or_vacation_type}) do
    %{data: data(holiday_or_vacation_type)}
  end

  defp data(type) do
    %{
      id: type.id,
      colloquial: type.colloquial,
      country_location_id: type.country_location_id,
      default_display_priority: type.default_display_priority,
      default_is_listed_below_month: type.default_is_listed_below_month,
      default_is_public_holiday: type.default_is_public_holiday,
      default_is_school_vacation: type.default_is_school_vacation,
      default_is_valid_for_everybody: type.default_is_valid_for_everybody,
      default_is_valid_for_students: type.default_is_valid_for_students,
      default_religion_id: type.default_religion_id,
      name: type.name,
      slug: type.slug,
      wikipedia_url: type.wikipedia_url,
      updated_at: type.updated_at
    }
  end
end