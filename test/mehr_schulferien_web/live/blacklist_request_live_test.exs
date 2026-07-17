defmodule MehrSchulferienWeb.BlacklistRequestLiveTest do
  use MehrSchulferienWeb.ConnCase

  # Blacklist request page requires wiki authentication

  import Phoenix.LiveViewTest

  describe "blacklist request page" do
    setup :log_in_wiki_user

    test "shows data entry form for authenticated user", %{conn: conn, current_user: user} do
      {:ok, _view, html} = live(conn, "/wiki/blacklist/request")

      # Shows user info
      assert html =~ "Angemeldet als:"
      assert html =~ user.full_name

      # Shows data entry form
      assert html =~ "Datensperrliste (Blacklist)"
      assert html =~ "Welche Daten sollen gesperrt werden?"
      assert html =~ "Art der Daten"
      assert html =~ "Zu sperrende Daten"
    end

    test "shows live preview when entering pattern", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/wiki/blacklist/request")

      # Enter a pattern
      html =
        view
        |> form("form", form: %{field_type: "phone_number", pattern: "+49 30 1234"})
        |> render_change()

      # Should show live preview
      assert html =~ "Live-Suche"
    end

    test "requires minimum pattern length", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/wiki/blacklist/request")

      # Enter a short pattern
      html =
        view
        |> form("form", form: %{field_type: "phone_number", pattern: "ab"})
        |> render_change()

      # Should show instruction about minimum length
      assert html =~ "mindestens 4 Zeichen"
    end

    test "shows sidebar help information", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/wiki/blacklist/request")

      # Check help content
      assert html =~ "Was ist die Datensperrliste?"
      assert html =~ "Mehrere Einträge sperren"
      assert html =~ "Sperrbare Daten:"
    end
  end

  describe "blacklist request page requires authentication" do
    test "redirects to login when not authenticated", %{conn: conn} do
      {:error, {:redirect, %{to: redirect_url}}} = live(conn, "/wiki/blacklist/request")

      # Redirect URL should be clean (return_to is stored in cookie, not URL)
      assert redirect_url == "/auth/login"

      # Verify the cookie is set with the return path
      conn = get(conn, "/wiki/blacklist/request")
      cookie = conn.resp_cookies["wiki_return_to"]
      assert cookie != nil
      assert cookie.value == "/wiki/blacklist/request"
    end
  end
end
