defmodule MehrSchulferienWeb.MCPDocumentationController do
  use MehrSchulferienWeb, :controller

  def index(conn, _params) do
    render(conn, :index, layout: {MehrSchulferienWeb.LayoutView, "app.html"})
  end
end
