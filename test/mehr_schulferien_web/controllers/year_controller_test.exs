defmodule MehrSchulferienWeb.YearControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Timetables

  @create_attrs %{slug: "some slug", value: 42}
  @update_attrs %{slug: "some updated slug", value: 43}
  @invalid_attrs %{slug: nil, value: nil}

  def fixture(:year) do
    {:ok, year} = Timetables.create_year(@create_attrs)
    year
  end

  describe "index" do
    test "lists all years", %{conn: conn} do
      conn = get conn, year_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Years"
    end
  end

  describe "new year" do
    test "renders form", %{conn: conn} do
      conn = get conn, year_path(conn, :new)
      assert html_response(conn, 200) =~ "New Year"
    end
  end

  describe "create year" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, year_path(conn, :create), year: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == year_path(conn, :show, id)

      conn = get conn, year_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Year"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, year_path(conn, :create), year: @invalid_attrs
      assert html_response(conn, 200) =~ "New Year"
    end
  end

  describe "edit year" do
    setup [:create_year]

    test "renders form for editing chosen year", %{conn: conn, year: year} do
      conn = get conn, year_path(conn, :edit, year)
      assert html_response(conn, 200) =~ "Edit Year"
    end
  end

  describe "update year" do
    setup [:create_year]

    test "redirects when data is valid", %{conn: conn, year: year} do
      conn = put conn, year_path(conn, :update, year), year: @update_attrs
      assert redirected_to(conn) == year_path(conn, :show, year)

      conn = get conn, year_path(conn, :show, year)
      assert html_response(conn, 200) =~ "some updated slug"
    end

    test "renders errors when data is invalid", %{conn: conn, year: year} do
      conn = put conn, year_path(conn, :update, year), year: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Year"
    end
  end

  describe "delete year" do
    setup [:create_year]

    test "deletes chosen year", %{conn: conn, year: year} do
      conn = delete conn, year_path(conn, :delete, year)
      assert redirected_to(conn) == year_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, year_path(conn, :show, year)
      end
    end
  end

  defp create_year(_) do
    year = fixture(:year)
    {:ok, year: year}
  end
end
