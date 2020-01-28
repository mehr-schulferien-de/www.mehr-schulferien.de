defmodule MehrSchulferienWeb.HolidayOrVacationTypeController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Calendars
  alias MehrSchulferien.Calendars.HolidayOrVacationType

  def index(conn, _params) do
    holiday_or_vacation_types = Calendars.list_holiday_or_vacation_types()
    render(conn, "index.html", holiday_or_vacation_types: holiday_or_vacation_types)
  end

  def new(conn, _params) do
    changeset = Calendars.change_holiday_or_vacation_type(%HolidayOrVacationType{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"holiday_or_vacation_type" => holiday_or_vacation_type_params}) do
    case Calendars.create_holiday_or_vacation_type(holiday_or_vacation_type_params) do
      {:ok, holiday_or_vacation_type} ->
        conn
        |> put_flash(:info, "Holiday or vacation type created successfully.")
        |> redirect(to: Routes.holiday_or_vacation_type_path(conn, :show, holiday_or_vacation_type))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    holiday_or_vacation_type = Calendars.get_holiday_or_vacation_type!(id)
    render(conn, "show.html", holiday_or_vacation_type: holiday_or_vacation_type)
  end

  def edit(conn, %{"id" => id}) do
    holiday_or_vacation_type = Calendars.get_holiday_or_vacation_type!(id)
    changeset = Calendars.change_holiday_or_vacation_type(holiday_or_vacation_type)
    render(conn, "edit.html", holiday_or_vacation_type: holiday_or_vacation_type, changeset: changeset)
  end

  def update(conn, %{"id" => id, "holiday_or_vacation_type" => holiday_or_vacation_type_params}) do
    holiday_or_vacation_type = Calendars.get_holiday_or_vacation_type!(id)

    case Calendars.update_holiday_or_vacation_type(holiday_or_vacation_type, holiday_or_vacation_type_params) do
      {:ok, holiday_or_vacation_type} ->
        conn
        |> put_flash(:info, "Holiday or vacation type updated successfully.")
        |> redirect(to: Routes.holiday_or_vacation_type_path(conn, :show, holiday_or_vacation_type))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", holiday_or_vacation_type: holiday_or_vacation_type, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    holiday_or_vacation_type = Calendars.get_holiday_or_vacation_type!(id)
    {:ok, _holiday_or_vacation_type} = Calendars.delete_holiday_or_vacation_type(holiday_or_vacation_type)

    conn
    |> put_flash(:info, "Holiday or vacation type deleted successfully.")
    |> redirect(to: Routes.holiday_or_vacation_type_path(conn, :index))
  end
end
