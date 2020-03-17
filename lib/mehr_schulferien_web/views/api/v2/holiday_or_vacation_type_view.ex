defmodule MehrSchulferienWeb.Api.V2.HolidayOrVacationTypeView do
  use MehrSchulferienWeb, :view

  def render("index.json", %{holiday_or_vacation_types: holiday_or_vacation_types}) do
    %{data: render_many(holiday_or_vacation_types, __MODULE__, "holiday_or_vacation_type.json")}
  end

  def render("show.json", %{holiday_or_vacation_type: holiday_or_vacation_type}) do
    %{data: render_one(holiday_or_vacation_type, __MODULE__, "holiday_or_vacation_type.json")}
  end

  def render("holiday_or_vacation_type.json", %{holiday_or_vacation_type: holiday_or_vacation_type}) do
    %{
      id: holiday_or_vacation_type.id,
      name: holiday_or_vacation_type.name,
      colloquial: holiday_or_vacation_type.colloquial,
      country_location_id: holiday_or_vacation_type.country_location_id,
      updated_at: holiday_or_vacation_type.updated_at
    }
  end
end
