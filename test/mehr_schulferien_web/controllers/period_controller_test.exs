defmodule MehrSchulferienWeb.PeriodControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Timetables

  @create_attrs %{ends_on: ~D[2010-04-17], for_anybody: true, for_students: true, is_a_religion: true, name: "some name", needs_exeat: true, slug: "some slug", source: "some source", starts_on: ~D[2010-04-17]}
  @update_attrs %{ends_on: ~D[2011-05-18], for_anybody: false, for_students: false, is_a_religion: false, name: "some updated name", needs_exeat: false, slug: "some updated slug", source: "some updated source", starts_on: ~D[2011-05-18]}
  @invalid_attrs %{ends_on: nil, for_anybody: nil, for_students: nil, is_a_religion: nil, name: nil, needs_exeat: nil, slug: nil, source: nil, starts_on: nil}

  def fixture(:period) do
    {:ok, period} = Timetables.create_period(@create_attrs)
    period
  end

  describe "index" do
    test "lists all periods", %{conn: conn} do
      conn = get conn, period_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Periods"
    end
  end

  describe "new period" do
    test "renders form", %{conn: conn} do
      conn = get conn, period_path(conn, :new)
      assert html_response(conn, 200) =~ "New Period"
    end
  end

  describe "create period" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, period_path(conn, :create), period: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == period_path(conn, :show, id)

      conn = get conn, period_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Period"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, period_path(conn, :create), period: @invalid_attrs
      assert html_response(conn, 200) =~ "New Period"
    end
  end

  describe "edit period" do
    setup [:create_period]

    test "renders form for editing chosen period", %{conn: conn, period: period} do
      conn = get conn, period_path(conn, :edit, period)
      assert html_response(conn, 200) =~ "Edit Period"
    end
  end

  describe "update period" do
    setup [:create_period]

    test "redirects when data is valid", %{conn: conn, period: period} do
      conn = put conn, period_path(conn, :update, period), period: @update_attrs
      assert redirected_to(conn) == period_path(conn, :show, period)

      conn = get conn, period_path(conn, :show, period)
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, period: period} do
      conn = put conn, period_path(conn, :update, period), period: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Period"
    end
  end

  describe "delete period" do
    setup [:create_period]

    test "deletes chosen period", %{conn: conn, period: period} do
      conn = delete conn, period_path(conn, :delete, period)
      assert redirected_to(conn) == period_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, period_path(conn, :show, period)
      end
    end
  end

  defp create_period(_) do
    period = fixture(:period)
    {:ok, period: period}
  end
end
