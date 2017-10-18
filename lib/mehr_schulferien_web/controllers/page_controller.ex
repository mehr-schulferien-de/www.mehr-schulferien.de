defmodule MehrSchulferienWeb.PageController do
  use MehrSchulferienWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
