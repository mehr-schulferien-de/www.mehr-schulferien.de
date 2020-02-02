defmodule MehrSchulferienWeb.ReligionControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Calendars

  @create_attrs %{
    name: "Christentum",
    wikipedia_url: "https://de.wikipedia.org/wiki/Christentum"
  }
  @update_attrs %{wikipedia_url: "https://de.m.wikipedia.org/wiki/Christentum"}
  @invalid_attrs %{name: nil}

  describe "read religion data" do
    setup [:create_religion]

    test "lists all religions", %{conn: conn} do
      conn = get(conn, Routes.religion_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Religions"
    end

    test "shows certain religion", %{conn: conn, religion: religion} do
      conn = get(conn, Routes.religion_path(conn, :show, religion))
      assert html_response(conn, 200) =~ "Show Religion"
    end
  end

  describe "renders forms" do
    test "shows form for new religion", %{conn: conn} do
      conn = get(conn, Routes.religion_path(conn, :new))
      assert html_response(conn, 200) =~ "New Religion"
    end

    test "shows form for editing religion", %{conn: conn} do
      religion = insert(:religion)
      conn = get(conn, Routes.religion_path(conn, :edit, religion))
      assert html_response(conn, 200) =~ "Edit Religion"
    end
  end

  describe "create religion" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.religion_path(conn, :create), religion: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.religion_path(conn, :show, id)

      conn = get(conn, Routes.religion_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Religion"
      assert Calendars.get_religion!(id)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.religion_path(conn, :create), religion: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Religion"
    end
  end

  describe "update religion" do
    setup [:create_religion]

    test "redirects when data is valid", %{conn: conn, religion: religion} do
      conn = put(conn, Routes.religion_path(conn, :update, religion), religion: @update_attrs)
      assert redirected_to(conn) == Routes.religion_path(conn, :show, religion)

      conn = get(conn, Routes.religion_path(conn, :show, religion))
      assert html_response(conn, 200) =~ "https://de.m.wikipedia.org/wiki/Christentum"
      religion = Calendars.get_religion!(religion.id)
      assert religion.wikipedia_url == "https://de.m.wikipedia.org/wiki/Christentum"
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
    religion = insert(:religion)
    {:ok, religion: religion}
  end
end
