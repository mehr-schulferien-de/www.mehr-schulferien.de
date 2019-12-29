defmodule MehrschulferienWeb.PageController do
  use MehrschulferienWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
