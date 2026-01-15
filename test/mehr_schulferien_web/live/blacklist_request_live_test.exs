defmodule MehrSchulferienWeb.BlacklistRequestLiveTest do
  use MehrSchulferienWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "blacklist request form" do
    test "submitting valid name and email shows success page with inbox instructions", %{
      conn: conn
    } do
      {:ok, view, html} = live(conn, "/wiki/blacklist/request")

      # Verify the initial form is displayed
      assert html =~ "Datensperrliste"
      assert html =~ "Schritt 1"
      assert html =~ "E-Mail zur Bestätigung senden"

      # Submit the form with valid data using string keys
      # Note: render_submit returns the rendered HTML of the new state
      html =
        view
        |> element("form")
        |> render_submit(%{
          "form" => %{"full_name" => "Max Mustermann", "email" => "test@example.com"}
        })

      # Verify success page is shown with inbox instructions
      assert html =~ "E-Mail wurde versendet"
      assert html =~ "test@example.com"
      assert html =~ "Öffnen Sie Ihre E-Mails"
      assert html =~ "Der Link ist 24 Stunden gültig"
      assert html =~ "Spam-Ordner"
    end

    test "form shows error for empty name", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/wiki/blacklist/request")

      view
      |> form("form", form: %{full_name: "", email: "test@example.com"})
      |> render_submit()

      html = render(view)

      assert html =~ "min. 2 Zeichen"
    end

    test "form shows error for invalid email", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/wiki/blacklist/request")

      view
      |> form("form", form: %{full_name: "Max Mustermann", email: "invalid-email"})
      |> render_submit()

      html = render(view)

      assert html =~ "E-Mail-Adresse"
    end

    test "page shows initial form elements", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/wiki/blacklist/request")

      # Check form fields
      assert html =~ "Vollständiger Name"
      assert html =~ "E-Mail-Adresse"

      # Check informational content
      assert html =~ "Was ist die Datensperrliste?"
      # Note: The apostrophe in "So funktioniert's:" is HTML encoded
      assert html =~ "So funktioniert"
      assert html =~ "Datenspeicherung"
    end

    test "shows rate limit error when too many requests", %{conn: conn} do
      email = "ratelimit-test-#{System.unique_integer([:positive])}@example.com"

      # Create 3 requests to hit the rate limit
      for _ <- 1..3 do
        MehrSchulferien.Blacklist.create_verification_request(%{
          full_name: "Test User",
          email: email
        })
      end

      {:ok, view, _html} = live(conn, "/wiki/blacklist/request")

      # Submit the form with the same email - should be rate limited
      html =
        view
        |> element("form")
        |> render_submit(%{
          "form" => %{"full_name" => "Test User", "email" => email}
        })

      # Verify rate limit error is shown
      assert html =~ "zu viele Anfragen"
    end
  end
end
