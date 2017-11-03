defmodule MehrSchulferienWeb.Admin.AirportController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.Airport

  def index(conn, _params) do
    airports = Locations.list_airports()
    render(conn, "index.html", airports: airports)
  end

  def new(conn, _params) do
    changeset = Locations.change_airport(%Airport{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"airport" => airport_params}) do
    case Locations.create_airport(airport_params) do
      {:ok, airport} ->
        conn
        |> put_flash(:info, "Airport created successfully.")
        |> redirect(to: admin_airport_path(conn, :show, airport))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    airport = Locations.get_airport!(id)
    render(conn, "show.html", airport: airport)
  end

  def edit(conn, %{"id" => id}) do
    airport = Locations.get_airport!(id)
    changeset = Locations.change_airport(airport)
    render(conn, "edit.html", airport: airport, changeset: changeset)
  end

  def update(conn, %{"id" => id, "airport" => airport_params}) do
    airport = Locations.get_airport!(id)

    case Locations.update_airport(airport, airport_params) do
      {:ok, airport} ->
        conn
        |> put_flash(:info, "Airport updated successfully.")
        |> redirect(to: admin_airport_path(conn, :show, airport))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", airport: airport, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    airport = Locations.get_airport!(id)
    {:ok, _airport} = Locations.delete_airport(airport)

    conn
    |> put_flash(:info, "Airport deleted successfully.")
    |> redirect(to: admin_airport_path(conn, :index))
  end
end
