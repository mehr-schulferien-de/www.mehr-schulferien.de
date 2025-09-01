defmodule MehrSchulferienWeb.Api.V2.PeriodJSON do
  def index(%{periods: periods}) do
    %{data: for(period <- periods, do: data(period))}
  end

  def show(%{period: period}) do
    %{data: data(period)}
  end

  defp data(period) do
    %{
      id: period.id,
      created_by_email_address: period.created_by_email_address,
      display_priority: period.display_priority,
      ends_on: period.ends_on,
      holiday_or_vacation_type_id: period.holiday_or_vacation_type_id,
      is_listed_below_month: period.is_listed_below_month,
      is_public_holiday: period.is_public_holiday,
      is_school_vacation: period.is_school_vacation,
      is_valid_for_everybody: period.is_valid_for_everybody,
      is_valid_for_students: period.is_valid_for_students,
      location_id: period.location_id,
      memo: period.memo,
      starts_on: period.starts_on,
      updated_at: period.updated_at
    }
  end
end