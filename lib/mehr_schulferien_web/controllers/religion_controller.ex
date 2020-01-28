defmodule MehrSchulferienWeb.ReligionController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Calendars
  alias MehrSchulferien.Calendars.Religion

  def index(conn, _params) do
    religions = Calendars.list_religions()
    render(conn, "index.html", religions: religions)
  end

  def new(conn, _params) do
    changeset = Calendars.change_religion(%Religion{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"religion" => religion_params}) do
    case Calendars.create_religion(religion_params) do
      {:ok, religion} ->
        conn
        |> put_flash(:info, "Religion created successfully.")
        |> redirect(to: Routes.religion_path(conn, :show, religion))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    religion = Calendars.get_religion!(id)
    render(conn, "show.html", religion: religion)
  end

  def edit(conn, %{"id" => id}) do
    religion = Calendars.get_religion!(id)
    changeset = Calendars.change_religion(religion)
    render(conn, "edit.html", religion: religion, changeset: changeset)
  end

  def update(conn, %{"id" => id, "religion" => religion_params}) do
    religion = Calendars.get_religion!(id)

    case Calendars.update_religion(religion, religion_params) do
      {:ok, religion} ->
        conn
        |> put_flash(:info, "Religion updated successfully.")
        |> redirect(to: Routes.religion_path(conn, :show, religion))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", religion: religion, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    religion = Calendars.get_religion!(id)
    {:ok, _religion} = Calendars.delete_religion(religion)

    conn
    |> put_flash(:info, "Religion deleted successfully.")
    |> redirect(to: Routes.religion_path(conn, :index))
  end
end
