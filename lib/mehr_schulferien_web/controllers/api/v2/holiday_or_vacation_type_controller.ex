defmodule MehrSchulferienWeb.Api.V2.HolidayOrVacationTypeController do
  use MehrSchulferienWeb, :controller

  def index(conn, _params) do
    holiday_or_vacation_types = MehrSchulferien.Calendars.list_holiday_or_vacation_types()
    render(conn, "index.json", holiday_or_vacation_types: holiday_or_vacation_types)
  end

  def show(conn, %{"id" => id}) do
    holiday_or_vacation_type = MehrSchulferien.Calendars.get_holiday_or_vacation_type!(id)
    render(conn, "show.json", holiday_or_vacation_type: holiday_or_vacation_type)
  end
end
