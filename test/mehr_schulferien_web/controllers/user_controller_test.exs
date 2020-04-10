defmodule MehrSchulferienWeb.UserControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Accounts

  @create_attrs %{email: "bill@example.com", password: "hard2guess"}
  @update_attrs %{email: "william@example.com"}
  @invalid_attrs %{email: nil}

  setup %{conn: conn} do
    conn = conn |> bypass_through(MehrSchulferienWeb.Router, [:browser]) |> get("/")
    {:ok, %{conn: conn}}
  end

  describe "renders forms" do
    setup [:add_user_session]

    test "renders form for new users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :new))
      assert html_response(conn, 200) =~ "Account anlegen"
    end

    test "renders form for editing chosen user", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_path(conn, :edit, user))
      assert html_response(conn, 200) =~ "Edit user"
    end
  end

  describe "show user resource" do
    setup [:add_user_session]

    test "show chosen user's page", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_path(conn, :show, user))
      assert html_response(conn, 200) =~ "Show user"
    end

    test "returns 404 when user not found", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, Routes.user_path(conn, :show, -1))
      end
    end
  end

  describe "create user" do
    test "creates user when data is valid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      assert redirected_to(conn) == Routes.session_path(conn, :new)
    end

    test "does not create user and renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert html_response(conn, 200) =~ "Account anlegen"
    end
  end

  describe "updates user" do
    setup [:add_user_session]

    test "updates chosen user when data is valid", %{conn: conn, user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
      assert redirected_to(conn) == Routes.user_path(conn, :show, user)
      updated_user = Accounts.get_user!(user.id)
      assert updated_user.email == "william@example.com"
      conn = get(conn, Routes.user_path(conn, :show, user))
      assert html_response(conn, 200) =~ "william@example.com"
    end

    test "does not update chosen user and renders errors when data is invalid", %{
      conn: conn,
      user: user
    } do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit user"
    end
  end

  describe "delete user" do
    setup [:add_user_session]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, Routes.user_path(conn, :delete, user))
      assert redirected_to(conn) == Routes.session_path(conn, :new)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "cannot delete other user", %{conn: conn, user: user} do
      other = add_user("tony@example.com")
      conn = delete(conn, Routes.user_path(conn, :delete, other))
      assert redirected_to(conn) == Routes.user_path(conn, :show, user)
      assert Accounts.get_user!(other.id)
    end
  end

  defp add_user_session(%{conn: conn}) do
    user = add_user("reg@example.com")
    conn = conn |> add_session(user) |> send_resp(:ok, "/")
    {:ok, %{conn: conn, user: user}}
  end
end
