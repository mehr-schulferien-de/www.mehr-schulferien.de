defmodule MehrSchulferienWeb.System.WikiAuthRedirectTest do
  @moduledoc """
  Tests for the wiki authentication redirect flow.

  Ensures that users are redirected back to their intended destination
  after logging in via the cookie-based return_to mechanism.
  """
  use MehrSchulferienWeb.ConnCase, async: false

  @moduletag :skip

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias MehrSchulferien.Accounts

  @cookie_name "wiki_return_to"

  describe "login redirect flow" do
    test "user clicking 'Schule nicht gefunden? Hier anlegen' is redirected back after login", %{
      conn: conn
    } do
      # Step 1: Non-logged-in user tries to access /wiki/schools/new
      # This should redirect to login and set a return_to cookie
      {:error, {:redirect, %{to: redirect_url}}} = live(conn, "/wiki/schools/new")

      # Redirect should be clean without query params
      assert redirect_url == "/auth/login"

      # Step 2: Follow the redirect to get the cookie
      conn = get(conn, "/wiki/schools/new")
      assert redirected_to(conn) == "/auth/login"

      # Cookie should be set with the return path
      cookie = conn.resp_cookies[@cookie_name]
      assert cookie != nil
      assert cookie.value == "/wiki/schools/new"

      # Step 3: User is now on login page
      conn_with_cookie =
        conn |> recycle() |> Map.put(:cookies, %{@cookie_name => "/wiki/schools/new"})

      {:ok, login_view, _html} = live(conn_with_cookie, "/auth/login")

      # Step 4: User enters their name and email
      email = "test-redirect-#{System.unique_integer()}@example.com"
      full_name = "Test User"

      login_view
      |> form("form", %{full_name: full_name, email: email})
      |> render_submit()

      # Step 5: Magic link email was sent WITHOUT return_to parameter
      assert_email_sent(fn email_sent ->
        assert email_sent.subject == "Anmeldung bei mehr-schulferien.de Wiki"
        # The magic link should NOT include return_to parameter
        refute email_sent.html_body =~ "return_to="
        assert email_sent.html_body =~ "/auth/verify/"
      end)

      # Step 6: Get the user and create a valid login token to simulate clicking the link
      user = Accounts.get_user_by_email(email)
      assert user != nil

      # Create a fresh login token (simulating the email link)
      {raw_token, token_hash} = MehrSchulferien.Accounts.UserToken.generate_token()

      {:ok, _token} =
        MehrSchulferien.Repo.insert(
          MehrSchulferien.Accounts.UserToken.login_token_changeset(%{
            user_id: user.id,
            token_hash: token_hash,
            ip_address: nil
          })
        )

      # Step 7: User clicks the magic link (clean URL, no return_to)
      # The conn needs to have the cookie set to simulate the real flow
      verify_conn =
        build_conn()
        |> put_req_cookie(@cookie_name, "/wiki/schools/new")
        |> get("/auth/verify/#{raw_token}")

      # Should redirect to the school creation form (from cookie)
      assert redirected_to(verify_conn) == "/wiki/schools/new"
      assert Phoenix.Flash.get(verify_conn.assigns.flash, :info) == "Erfolgreich angemeldet."

      # Cookie should be deleted after use
      deleted_cookie = verify_conn.resp_cookies[@cookie_name]
      assert deleted_cookie.max_age == 0
    end

    test "user trying to access wiki hub is redirected back after login", %{conn: conn} do
      # Try to access /wiki - should redirect to login
      {:error, {:redirect, %{to: redirect_url}}} = live(conn, "/wiki")

      assert redirect_url == "/auth/login"

      # Follow the redirect to verify cookie is set
      conn = get(conn, "/wiki")
      cookie = conn.resp_cookies[@cookie_name]
      assert cookie != nil
      assert cookie.value == "/wiki"
    end

    test "user trying to access wiki periods is redirected back after login", %{conn: conn} do
      # Try to access /wiki/periods
      {:error, {:redirect, %{to: redirect_url}}} = live(conn, "/wiki/periods")

      assert redirect_url == "/auth/login"

      # Follow the redirect to verify cookie is set
      conn = get(conn, "/wiki/periods")
      cookie = conn.resp_cookies[@cookie_name]
      assert cookie != nil
      assert cookie.value == "/wiki/periods"
    end

    test "user trying to access wiki periods/new is redirected back after login", %{conn: conn} do
      # Try to access /wiki/periods/new
      {:error, {:redirect, %{to: redirect_url}}} = live(conn, "/wiki/periods/new")

      assert redirect_url == "/auth/login"

      # Follow the redirect to verify cookie is set
      conn = get(conn, "/wiki/periods/new")
      cookie = conn.resp_cookies[@cookie_name]
      assert cookie != nil
      assert cookie.value == "/wiki/periods/new"
    end

    test "verify without cookie defaults to /wiki", %{conn: conn} do
      # Create a user and token
      email = "test-no-cookie-#{System.unique_integer()}@example.com"
      {:ok, user} = Accounts.get_or_create_user_by_email(email, full_name: "Test User")

      {raw_token, token_hash} = MehrSchulferien.Accounts.UserToken.generate_token()

      {:ok, _token} =
        MehrSchulferien.Repo.insert(
          MehrSchulferien.Accounts.UserToken.login_token_changeset(%{
            user_id: user.id,
            token_hash: token_hash,
            ip_address: nil
          })
        )

      # Verify without any cookie
      conn = get(conn, "/auth/verify/#{raw_token}")

      # Should default to /wiki
      assert redirected_to(conn) == "/wiki"
    end

    test "authenticated user can access wiki directly", %{conn: conn} do
      # Create and login user
      email = "test-direct-#{System.unique_integer()}@example.com"
      {:ok, user} = Accounts.get_or_create_user_by_email(email, full_name: "Test User")
      conn = log_in_user(conn, user)

      # Should be able to access wiki directly
      {:ok, _view, html} = live(conn, "/wiki")
      assert html =~ "Wiki - Gemeinsam mehr Schulferien"
    end

    test "authenticated user can access create school form directly", %{conn: conn} do
      # Create and login user
      email = "test-school-form-#{System.unique_integer()}@example.com"
      {:ok, user} = Accounts.get_or_create_user_by_email(email, full_name: "Test User")
      conn = log_in_user(conn, user)

      # Should be able to access create school form directly
      {:ok, _view, html} = live(conn, "/wiki/schools/new")
      assert html =~ "Neue Schule anlegen"
    end
  end
end
