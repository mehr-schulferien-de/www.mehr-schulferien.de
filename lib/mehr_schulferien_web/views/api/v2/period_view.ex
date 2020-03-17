defmodule MehrSchulferienWeb.Api.V2.PeriodView do
  use MehrSchulferienWeb, :view

  def render("index.json", %{periods: periods}) do
    %{data: render_many(periods, __MODULE__, "period.json")}
  end

  def render("show.json", %{period: period}) do
    %{data: render_one(period, __MODULE__, "period.json")}
  end

  def render("period.json", %{period: period}) do
    %{
      id: period.id,
      starts_on: period.starts_on,
      ends_on: period.ends_on,
      is_public_holiday: period.is_public_holiday,
      is_school_vacation: period.is_school_vacation,
      is_valid_for_everybody: period.is_valid_for_everybody,
      is_valid_for_students: period.is_valid_for_students,
      holiday_or_vacation_type_id: period.holiday_or_vacation_type_id,
      location_id: period.location_id,
      updated_at: period.updated_at
    }
  end
end
