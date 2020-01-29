defmodule MehrSchulferienWeb.PeriodControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Calendars

  @create_attrs %{created_by_email_address: "some created_by_email_address", ends_on: ~D[2010-04-17], html_class: "some html_class", is_listed_below_month: true, is_public_holiday: true, is_school_vacation: true, is_valid_for_everybody: true, is_valid_for_students: true, starts_on: ~D[2010-04-17]}
  @update_attrs %{created_by_email_address: "some updated created_by_email_address", ends_on: ~D[2011-05-18], html_class: "some updated html_class", is_listed_below_month: false, is_public_holiday: false, is_school_vacation: false, is_valid_for_everybody: false, is_valid_for_students: false, starts_on: ~D[2011-05-18]}
  @invalid_attrs %{created_by_email_address: nil, ends_on: nil, html_class: nil, is_listed_below_month: nil, is_public_holiday: nil, is_school_vacation: nil, is_valid_for_everybody: nil, is_valid_for_students: nil, starts_on: nil}

  def fixture(:period) do
    {:ok, period} = Calendars.create_period(@create_attrs)
    period
  end

  describe "index" do
    test "lists all periods", %{conn: conn} do
      conn = get(conn, Routes.period_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Periods"
    end
  end

  describe "new period" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.period_path(conn, :new))
      assert html_response(conn, 200) =~ "New Period"
    end
  end

  describe "create period" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.period_path(conn, :create), period: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.period_path(conn, :show, id)

      conn = get(conn, Routes.period_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Period"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.period_path(conn, :create), period: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Period"
    end
  end

  describe "edit period" do
    setup [:create_period]

    test "renders form for editing chosen period", %{conn: conn, period: period} do
      conn = get(conn, Routes.period_path(conn, :edit, period))
      assert html_response(conn, 200) =~ "Edit Period"
    end
  end

  describe "update period" do
    setup [:create_period]

    test "redirects when data is valid", %{conn: conn, period: period} do
      conn = put(conn, Routes.period_path(conn, :update, period), period: @update_attrs)
      assert redirected_to(conn) == Routes.period_path(conn, :show, period)

      conn = get(conn, Routes.period_path(conn, :show, period))
      assert html_response(conn, 200) =~ "some updated created_by_email_address"
    end

    test "renders errors when data is invalid", %{conn: conn, period: period} do
      conn = put(conn, Routes.period_path(conn, :update, period), period: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Period"
    end
  end

  describe "delete period" do
    setup [:create_period]

    test "deletes chosen period", %{conn: conn, period: period} do
      conn = delete(conn, Routes.period_path(conn, :delete, period))
      assert redirected_to(conn) == Routes.period_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.period_path(conn, :show, period))
      end
    end
  end

  defp create_period(_) do
    period = fixture(:period)
    {:ok, period: period}
  end
end
