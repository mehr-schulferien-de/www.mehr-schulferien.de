defmodule MehrSchulferienWeb.SchoolController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Institutions
  alias MehrSchulferien.Institutions.School

  def index(conn, _params) do
    schools = Institutions.list_schools()
    render(conn, "index.html", schools: schools)
  end

  def new(conn, _params) do
    changeset = Institutions.change_school(%School{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"school" => school_params}) do
    case Institutions.create_school(school_params) do
      {:ok, school} ->
        conn
        |> put_flash(:info, "School created successfully.")
        |> redirect(to: Routes.school_path(conn, :show, school))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    school = Institutions.get_school!(id)
    render(conn, "show.html", school: school)
  end

  def edit(conn, %{"id" => id}) do
    school = Institutions.get_school!(id)
    changeset = Institutions.change_school(school)
    render(conn, "edit.html", school: school, changeset: changeset)
  end

  def update(conn, %{"id" => id, "school" => school_params}) do
    school = Institutions.get_school!(id)

    case Institutions.update_school(school, school_params) do
      {:ok, school} ->
        conn
        |> put_flash(:info, "School updated successfully.")
        |> redirect(to: Routes.school_path(conn, :show, school))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", school: school, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    school = Institutions.get_school!(id)
    {:ok, _school} = Institutions.delete_school(school)

    conn
    |> put_flash(:info, "School deleted successfully.")
    |> redirect(to: Routes.school_path(conn, :index))
  end
end
