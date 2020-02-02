defmodule MehrSchulferienWeb.PeriodControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Calendars

  @create_attrs %{
    created_by_email_address: "george@example.com",
    ends_on: ~D[2010-04-20],
    starts_on: ~D[2010-04-17]
  }
  @update_attrs %{
    html_class: "white",
    is_public_holiday: true
  }
  @invalid_attrs %{created_by_email_address: nil}

  describe "read period data" do
    setup [:create_period]

    test "lists all periods", %{conn: conn} do
      conn = get(conn, Routes.period_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Periods"
    end

    test "shows certain period", %{conn: conn, period: period} do
      conn = get(conn, Routes.period_path(conn, :show, period))
      assert html_response(conn, 200) =~ "Show Period"
    end
  end

  describe "renders forms" do
    test "shows form for new period", %{conn: conn} do
      conn = get(conn, Routes.period_path(conn, :new))
      assert html_response(conn, 200) =~ "New Period"
    end

    test "renders form for editing chosen period", %{conn: conn} do
      period = insert(:period)
      conn = get(conn, Routes.period_path(conn, :edit, period))
      assert html_response(conn, 200) =~ "Edit Period"
    end
  end

  describe "create period" do
    test "redirects to show when data is valid", %{conn: conn} do
      location = insert(:location)
      holiday_or_vacation_type = insert(:holiday_or_vacation_type)

      create_attrs =
        Map.merge(@create_attrs, %{
          holiday_or_vacation_type_id: holiday_or_vacation_type.id,
          location_id: location.id
        })

      conn = post(conn, Routes.period_path(conn, :create), period: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.period_path(conn, :show, id)

      conn = get(conn, Routes.period_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Period"
      assert Calendars.get_period!(id)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.period_path(conn, :create), period: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Period"
    end
  end

  describe "update period" do
    setup [:create_period]

    test "redirects when data is valid", %{conn: conn, period: period} do
      assert period.is_public_holiday == false
      conn = put(conn, Routes.period_path(conn, :update, period), period: @update_attrs)
      assert redirected_to(conn) == Routes.period_path(conn, :show, period)

      conn = get(conn, Routes.period_path(conn, :show, period))
      assert html_response(conn, 200) =~ "white"
      period = Calendars.get_period!(period.id)
      assert period.is_public_holiday == true
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
    period = insert(:period)
    {:ok, period: period}
  end
end
