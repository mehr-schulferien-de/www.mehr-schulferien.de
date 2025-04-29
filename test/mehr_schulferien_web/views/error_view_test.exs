defmodule MehrSchulferienWeb.ErrorViewTest do
  use MehrSchulferienWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html" do
    html = render_to_string(MehrSchulferienWeb.ErrorView, "404.html", [])
    assert html =~ "404"
    assert html =~ "Not Found"
    assert html =~ "Die angeforderte Seite wurde nicht gefunden"
  end

  test "renders 500.html" do
    html = render_to_string(MehrSchulferienWeb.ErrorView, "500.html", [])
    assert html == "Internal Server Error"
  end
end
