defmodule MehrSchulferienWeb.HolidayOrVacationTypeControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Calendars

  @create_attrs %{colloquial: "some colloquial", default_html_class: "some default_html_class", default_is_listed_below_month: true, default_is_public_holiday: true, default_is_school_vacation: true, default_is_valid_for_everybody: true, default_is_valid_for_students: true, name: "some name", slug: "some slug", wikipedia_url: "some wikipedia_url"}
  @update_attrs %{colloquial: "some updated colloquial", default_html_class: "some updated default_html_class", default_is_listed_below_month: false, default_is_public_holiday: false, default_is_school_vacation: false, default_is_valid_for_everybody: false, default_is_valid_for_students: false, name: "some updated name", slug: "some updated slug", wikipedia_url: "some updated wikipedia_url"}
  @invalid_attrs %{colloquial: nil, default_html_class: nil, default_is_listed_below_month: nil, default_is_public_holiday: nil, default_is_school_vacation: nil, default_is_valid_for_everybody: nil, default_is_valid_for_students: nil, name: nil, slug: nil, wikipedia_url: nil}

  def fixture(:holiday_or_vacation_type) do
    {:ok, holiday_or_vacation_type} = Calendars.create_holiday_or_vacation_type(@create_attrs)
    holiday_or_vacation_type
  end

  describe "index" do
    test "lists all holiday_or_vacation_types", %{conn: conn} do
      conn = get(conn, Routes.holiday_or_vacation_type_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Holiday or vacation types"
    end
  end

  describe "new holiday_or_vacation_type" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.holiday_or_vacation_type_path(conn, :new))
      assert html_response(conn, 200) =~ "New Holiday or vacation type"
    end
  end

  describe "create holiday_or_vacation_type" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.holiday_or_vacation_type_path(conn, :create), holiday_or_vacation_type: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.holiday_or_vacation_type_path(conn, :show, id)

      conn = get(conn, Routes.holiday_or_vacation_type_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Holiday or vacation type"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.holiday_or_vacation_type_path(conn, :create), holiday_or_vacation_type: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Holiday or vacation type"
    end
  end

  describe "edit holiday_or_vacation_type" do
    setup [:create_holiday_or_vacation_type]

    test "renders form for editing chosen holiday_or_vacation_type", %{conn: conn, holiday_or_vacation_type: holiday_or_vacation_type} do
      conn = get(conn, Routes.holiday_or_vacation_type_path(conn, :edit, holiday_or_vacation_type))
      assert html_response(conn, 200) =~ "Edit Holiday or vacation type"
    end
  end

  describe "update holiday_or_vacation_type" do
    setup [:create_holiday_or_vacation_type]

    test "redirects when data is valid", %{conn: conn, holiday_or_vacation_type: holiday_or_vacation_type} do
      conn = put(conn, Routes.holiday_or_vacation_type_path(conn, :update, holiday_or_vacation_type), holiday_or_vacation_type: @update_attrs)
      assert redirected_to(conn) == Routes.holiday_or_vacation_type_path(conn, :show, holiday_or_vacation_type)

      conn = get(conn, Routes.holiday_or_vacation_type_path(conn, :show, holiday_or_vacation_type))
      assert html_response(conn, 200) =~ "some updated colloquial"
    end

    test "renders errors when data is invalid", %{conn: conn, holiday_or_vacation_type: holiday_or_vacation_type} do
      conn = put(conn, Routes.holiday_or_vacation_type_path(conn, :update, holiday_or_vacation_type), holiday_or_vacation_type: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Holiday or vacation type"
    end
  end

  describe "delete holiday_or_vacation_type" do
    setup [:create_holiday_or_vacation_type]

    test "deletes chosen holiday_or_vacation_type", %{conn: conn, holiday_or_vacation_type: holiday_or_vacation_type} do
      conn = delete(conn, Routes.holiday_or_vacation_type_path(conn, :delete, holiday_or_vacation_type))
      assert redirected_to(conn) == Routes.holiday_or_vacation_type_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.holiday_or_vacation_type_path(conn, :show, holiday_or_vacation_type))
      end
    end
  end

  defp create_holiday_or_vacation_type(_) do
    holiday_or_vacation_type = fixture(:holiday_or_vacation_type)
    {:ok, holiday_or_vacation_type: holiday_or_vacation_type}
  end
end
