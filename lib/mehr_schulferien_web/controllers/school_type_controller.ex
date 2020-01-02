defmodule MehrSchulferienWeb.SchoolTypeController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Institutions
  alias MehrSchulferien.Institutions.SchoolType

  def index(conn, _params) do
    school_types = Institutions.list_school_types()
    render(conn, "index.html", school_types: school_types)
  end

  def new(conn, _params) do
    changeset = Institutions.change_school_type(%SchoolType{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"school_type" => school_type_params}) do
    case Institutions.create_school_type(school_type_params) do
      {:ok, school_type} ->
        conn
        |> put_flash(:info, "School type created successfully.")
        |> redirect(to: Routes.school_type_path(conn, :show, school_type))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    school_type = Institutions.get_school_type!(id)
    render(conn, "show.html", school_type: school_type)
  end

  def edit(conn, %{"id" => id}) do
    school_type = Institutions.get_school_type!(id)
    changeset = Institutions.change_school_type(school_type)
    render(conn, "edit.html", school_type: school_type, changeset: changeset)
  end

  def update(conn, %{"id" => id, "school_type" => school_type_params}) do
    school_type = Institutions.get_school_type!(id)

    case Institutions.update_school_type(school_type, school_type_params) do
      {:ok, school_type} ->
        conn
        |> put_flash(:info, "School type updated successfully.")
        |> redirect(to: Routes.school_type_path(conn, :show, school_type))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", school_type: school_type, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    school_type = Institutions.get_school_type!(id)
    {:ok, _school_type} = Institutions.delete_school_type(school_type)

    conn
    |> put_flash(:info, "School type deleted successfully.")
    |> redirect(to: Routes.school_type_path(conn, :index))
  end
end
