defmodule MehrSchulferienWeb.ReligionControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Calendars

  @create_attrs %{name: "some name", slug: "some slug", wikipedia_url: "some wikipedia_url"}
  @update_attrs %{name: "some updated name", slug: "some updated slug", wikipedia_url: "some updated wikipedia_url"}
  @invalid_attrs %{name: nil, slug: nil, wikipedia_url: nil}

  def fixture(:religion) do
    {:ok, religion} = Calendars.create_religion(@create_attrs)
    religion
  end

  describe "index" do
    test "lists all religions", %{conn: conn} do
      conn = get(conn, Routes.religion_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Religions"
    end
  end

  describe "new religion" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.religion_path(conn, :new))
      assert html_response(conn, 200) =~ "New Religion"
    end
  end

  describe "create religion" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.religion_path(conn, :create), religion: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.religion_path(conn, :show, id)

      conn = get(conn, Routes.religion_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Religion"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.religion_path(conn, :create), religion: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Religion"
    end
  end

  describe "edit religion" do
    setup [:create_religion]

    test "renders form for editing chosen religion", %{conn: conn, religion: religion} do
      conn = get(conn, Routes.religion_path(conn, :edit, religion))
      assert html_response(conn, 200) =~ "Edit Religion"
    end
  end

  describe "update religion" do
    setup [:create_religion]

    test "redirects when data is valid", %{conn: conn, religion: religion} do
      conn = put(conn, Routes.religion_path(conn, :update, religion), religion: @update_attrs)
      assert redirected_to(conn) == Routes.religion_path(conn, :show, religion)

      conn = get(conn, Routes.religion_path(conn, :show, religion))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, religion: religion} do
      conn = put(conn, Routes.religion_path(conn, :update, religion), religion: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Religion"
    end
  end

  describe "delete religion" do
    setup [:create_religion]

    test "deletes chosen religion", %{conn: conn, religion: religion} do
      conn = delete(conn, Routes.religion_path(conn, :delete, religion))
      assert redirected_to(conn) == Routes.religion_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.religion_path(conn, :show, religion))
      end
    end
  end

  defp create_religion(_) do
    religion = fixture(:religion)
    {:ok, religion: religion}
  end
end
