defmodule MehrSchulferienWeb.ZipCodeController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Maps
  alias MehrSchulferien.Maps.ZipCode

  def index(conn, _params) do
    zip_codes = Maps.list_zip_codes()
    render(conn, "index.html", zip_codes: zip_codes)
  end

  def new(conn, _params) do
    changeset = Maps.change_zip_code(%ZipCode{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"zip_code" => zip_code_params}) do
    case Maps.create_zip_code(zip_code_params) do
      {:ok, zip_code} ->
        conn
        |> put_flash(:info, "Zip code created successfully.")
        |> redirect(to: Routes.zip_code_path(conn, :show, zip_code))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    zip_code = Maps.get_zip_code!(id)
    render(conn, "show.html", zip_code: zip_code)
  end

  def edit(conn, %{"id" => id}) do
    zip_code = Maps.get_zip_code!(id)
    changeset = Maps.change_zip_code(zip_code)
    render(conn, "edit.html", zip_code: zip_code, changeset: changeset)
  end

  def update(conn, %{"id" => id, "zip_code" => zip_code_params}) do
    zip_code = Maps.get_zip_code!(id)

    case Maps.update_zip_code(zip_code, zip_code_params) do
      {:ok, zip_code} ->
        conn
        |> put_flash(:info, "Zip code updated successfully.")
        |> redirect(to: Routes.zip_code_path(conn, :show, zip_code))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", zip_code: zip_code, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    zip_code = Maps.get_zip_code!(id)
    {:ok, _zip_code} = Maps.delete_zip_code(zip_code)

    conn
    |> put_flash(:info, "Zip code deleted successfully.")
    |> redirect(to: Routes.zip_code_path(conn, :index))
  end
end
