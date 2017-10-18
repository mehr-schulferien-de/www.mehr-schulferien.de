defmodule MehrSchulferienWeb.MonthController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Timetables
  alias MehrSchulferien.Timetables.Month

  def index(conn, _params) do
    months = Timetables.list_months()
    render(conn, "index.html", months: months)
  end

  def new(conn, _params) do
    changeset = Timetables.change_month(%Month{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"month" => month_params}) do
    case Timetables.create_month(month_params) do
      {:ok, month} ->
        conn
        |> put_flash(:info, "Month created successfully.")
        |> redirect(to: month_path(conn, :show, month))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    month = Timetables.get_month!(id)
    render(conn, "show.html", month: month)
  end

  def edit(conn, %{"id" => id}) do
    month = Timetables.get_month!(id)
    changeset = Timetables.change_month(month)
    render(conn, "edit.html", month: month, changeset: changeset)
  end

  def update(conn, %{"id" => id, "month" => month_params}) do
    month = Timetables.get_month!(id)

    case Timetables.update_month(month, month_params) do
      {:ok, month} ->
        conn
        |> put_flash(:info, "Month updated successfully.")
        |> redirect(to: month_path(conn, :show, month))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", month: month, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    month = Timetables.get_month!(id)
    {:ok, _month} = Timetables.delete_month(month)

    conn
    |> put_flash(:info, "Month deleted successfully.")
    |> redirect(to: month_path(conn, :index))
  end
end
