defmodule MehrSchulferienWeb.ZipCodeMappingController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Maps
  alias MehrSchulferien.Maps.ZipCodeMapping

  def index(conn, _params) do
    zip_code_mappings = Maps.list_zip_code_mappings()
    render(conn, "index.html", zip_code_mappings: zip_code_mappings)
  end

  def new(conn, _params) do
    changeset = Maps.change_zip_code_mapping(%ZipCodeMapping{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"zip_code_mapping" => zip_code_mapping_params}) do
    case Maps.create_zip_code_mapping(zip_code_mapping_params) do
      {:ok, zip_code_mapping} ->
        conn
        |> put_flash(:info, "Zip code mapping created successfully.")
        |> redirect(to: Routes.zip_code_mapping_path(conn, :show, zip_code_mapping))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    zip_code_mapping = Maps.get_zip_code_mapping!(id)
    render(conn, "show.html", zip_code_mapping: zip_code_mapping)
  end

  def edit(conn, %{"id" => id}) do
    zip_code_mapping = Maps.get_zip_code_mapping!(id)
    changeset = Maps.change_zip_code_mapping(zip_code_mapping)
    render(conn, "edit.html", zip_code_mapping: zip_code_mapping, changeset: changeset)
  end

  def update(conn, %{"id" => id, "zip_code_mapping" => zip_code_mapping_params}) do
    zip_code_mapping = Maps.get_zip_code_mapping!(id)

    case Maps.update_zip_code_mapping(zip_code_mapping, zip_code_mapping_params) do
      {:ok, zip_code_mapping} ->
        conn
        |> put_flash(:info, "Zip code mapping updated successfully.")
        |> redirect(to: Routes.zip_code_mapping_path(conn, :show, zip_code_mapping))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", zip_code_mapping: zip_code_mapping, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    zip_code_mapping = Maps.get_zip_code_mapping!(id)
    {:ok, _zip_code_mapping} = Maps.delete_zip_code_mapping(zip_code_mapping)

    conn
    |> put_flash(:info, "Zip code mapping deleted successfully.")
    |> redirect(to: Routes.zip_code_mapping_path(conn, :index))
  end
end
