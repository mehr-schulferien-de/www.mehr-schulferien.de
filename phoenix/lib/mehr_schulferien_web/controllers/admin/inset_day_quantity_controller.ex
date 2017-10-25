defmodule MehrSchulferienWeb.Admin.InsetDayQuantityController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Timetables
  alias MehrSchulferien.Timetables.InsetDayQuantity

  def index(conn, _params) do
    inset_day_quantities = Timetables.list_inset_day_quantities()
    render(conn, "index.html", inset_day_quantities: inset_day_quantities)
  end

  def new(conn, _params) do
    changeset = Timetables.change_inset_day_quantity(%InsetDayQuantity{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"inset_day_quantity" => inset_day_quantity_params}) do
    case Timetables.create_inset_day_quantity(inset_day_quantity_params) do
      {:ok, inset_day_quantity} ->
        conn
        |> put_flash(:info, "Inset day quantity created successfully.")
        |> redirect(to: admin_inset_day_quantity_path(conn, :show, inset_day_quantity))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    inset_day_quantity = Timetables.get_inset_day_quantity!(id)
    render(conn, "show.html", inset_day_quantity: inset_day_quantity)
  end

  def edit(conn, %{"id" => id}) do
    inset_day_quantity = Timetables.get_inset_day_quantity!(id)
    changeset = Timetables.change_inset_day_quantity(inset_day_quantity)
    render(conn, "edit.html", inset_day_quantity: inset_day_quantity, changeset: changeset)
  end

  def update(conn, %{"id" => id, "inset_day_quantity" => inset_day_quantity_params}) do
    inset_day_quantity = Timetables.get_inset_day_quantity!(id)

    case Timetables.update_inset_day_quantity(inset_day_quantity, inset_day_quantity_params) do
      {:ok, inset_day_quantity} ->
        conn
        |> put_flash(:info, "Inset day quantity updated successfully.")
        |> redirect(to: admin_inset_day_quantity_path(conn, :show, inset_day_quantity))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", inset_day_quantity: inset_day_quantity, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    inset_day_quantity = Timetables.get_inset_day_quantity!(id)
    {:ok, _inset_day_quantity} = Timetables.delete_inset_day_quantity(inset_day_quantity)

    conn
    |> put_flash(:info, "Inset day quantity deleted successfully.")
    |> redirect(to: admin_inset_day_quantity_path(conn, :index))
  end
end
