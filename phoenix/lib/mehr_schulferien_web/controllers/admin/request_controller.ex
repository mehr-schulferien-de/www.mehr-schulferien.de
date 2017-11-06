defmodule MehrSchulferienWeb.Admin.RequestController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Ads
  alias MehrSchulferien.Ads.Request
  alias MehrSchulferien.Repo
  import Ecto.Query, only: [from: 2]

  def index(conn, _params) do
    query = from r in Request, preload: [:travel_offer]
    requests = Repo.all(query)

    render(conn, "index.html", requests: requests)
  end

  def new(conn, _params) do
    changeset = Ads.change_request(%Request{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"request" => request_params}) do
    case Ads.create_request(request_params) do
      {:ok, request} ->
        conn
        |> put_flash(:info, "Request created successfully.")
        |> redirect(to: admin_request_path(conn, :show, request))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    request = Ads.get_request!(id)
    render(conn, "show.html", request: request)
  end

  def edit(conn, %{"id" => id}) do
    request = Ads.get_request!(id)
    changeset = Ads.change_request(request)
    render(conn, "edit.html", request: request, changeset: changeset)
  end

  def update(conn, %{"id" => id, "request" => request_params}) do
    request = Ads.get_request!(id)

    case Ads.update_request(request, request_params) do
      {:ok, request} ->
        conn
        |> put_flash(:info, "Request updated successfully.")
        |> redirect(to: admin_request_path(conn, :show, request))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", request: request, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    request = Ads.get_request!(id)
    {:ok, _request} = Ads.delete_request(request)

    conn
    |> put_flash(:info, "Request deleted successfully.")
    |> redirect(to: admin_request_path(conn, :index))
  end
end
