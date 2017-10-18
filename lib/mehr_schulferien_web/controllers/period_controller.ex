defmodule MehrSchulferienWeb.PeriodController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Timetables
  alias MehrSchulferien.Timetables.Period

  def index(conn, _params) do
    periods = Timetables.list_periods()
    render(conn, "index.html", periods: periods)
  end

  def new(conn, _params) do
    changeset = Timetables.change_period(%Period{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"period" => period_params}) do
    case Timetables.create_period(period_params) do
      {:ok, period} ->
        conn
        |> put_flash(:info, "Period created successfully.")
        |> redirect(to: period_path(conn, :show, period))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    period = Timetables.get_period!(id)
    render(conn, "show.html", period: period)
  end

  def edit(conn, %{"id" => id}) do
    period = Timetables.get_period!(id)
    changeset = Timetables.change_period(period)
    render(conn, "edit.html", period: period, changeset: changeset)
  end

  def update(conn, %{"id" => id, "period" => period_params}) do
    period = Timetables.get_period!(id)

    case Timetables.update_period(period, period_params) do
      {:ok, period} ->
        conn
        |> put_flash(:info, "Period updated successfully.")
        |> redirect(to: period_path(conn, :show, period))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", period: period, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    period = Timetables.get_period!(id)
    {:ok, _period} = Timetables.delete_period(period)

    conn
    |> put_flash(:info, "Period deleted successfully.")
    |> redirect(to: period_path(conn, :index))
  end
end
