defmodule MehrSchulferienWeb.MonthControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Timetables

  @create_attrs %{slug: "some slug", value: 42}
  @update_attrs %{slug: "some updated slug", value: 43}
  @invalid_attrs %{slug: nil, value: nil}

  def fixture(:month) do
    {:ok, month} = Timetables.create_month(@create_attrs)
    month
  end

  describe "index" do
    test "lists all months", %{conn: conn} do
      conn = get conn, month_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Months"
    end
  end

  describe "new month" do
    test "renders form", %{conn: conn} do
      conn = get conn, month_path(conn, :new)
      assert html_response(conn, 200) =~ "New Month"
    end
  end

  describe "create month" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, month_path(conn, :create), month: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == month_path(conn, :show, id)

      conn = get conn, month_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Month"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, month_path(conn, :create), month: @invalid_attrs
      assert html_response(conn, 200) =~ "New Month"
    end
  end

  describe "edit month" do
    setup [:create_month]

    test "renders form for editing chosen month", %{conn: conn, month: month} do
      conn = get conn, month_path(conn, :edit, month)
      assert html_response(conn, 200) =~ "Edit Month"
    end
  end

  describe "update month" do
    setup [:create_month]

    test "redirects when data is valid", %{conn: conn, month: month} do
      conn = put conn, month_path(conn, :update, month), month: @update_attrs
      assert redirected_to(conn) == month_path(conn, :show, month)

      conn = get conn, month_path(conn, :show, month)
      assert html_response(conn, 200) =~ "some updated slug"
    end

    test "renders errors when data is invalid", %{conn: conn, month: month} do
      conn = put conn, month_path(conn, :update, month), month: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Month"
    end
  end

  describe "delete month" do
    setup [:create_month]

    test "deletes chosen month", %{conn: conn, month: month} do
      conn = delete conn, month_path(conn, :delete, month)
      assert redirected_to(conn) == month_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, month_path(conn, :show, month)
      end
    end
  end

  defp create_month(_) do
    month = fixture(:month)
    {:ok, month: month}
  end
end
