defmodule MehrSchulferienWeb.HolidayOrVacationTypeControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Calendars

  @create_attrs %{
    colloquial: "Weihnachtsferien",
    default_display_priority: 3,
    default_html_class: "green",
    default_is_listed_below_month: true,
    default_is_school_vacation: true,
    default_is_valid_for_students: true,
    name: "Weihnachten",
    wikipedia_url: "https://de.wikipedia.org/wiki/Schulferien#Weihnachtsferien"
  }
  @update_attrs %{
    default_html_class: "blue",
    default_is_listed_below_month: false,
    default_is_school_vacation: false
  }
  @invalid_attrs %{name: nil}

  describe "read holiday_or_vacation_type data" do
    setup [:create_holiday_or_vacation_type]

    test "lists all holiday_or_vacation_types", %{conn: conn} do
      conn = get(conn, Routes.holiday_or_vacation_type_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Holiday or vacation types"
    end

    test "shows certain holiday_or_vacation_type", %{
      conn: conn,
      holiday_or_vacation_type: holiday_or_vacation_type
    } do
      conn =
        get(conn, Routes.holiday_or_vacation_type_path(conn, :show, holiday_or_vacation_type))

      assert html_response(conn, 200) =~ "Show Holiday or vacation type"
    end
  end

  describe "renders forms" do
    test "shows form for new holiday_or_vacation_type", %{conn: conn} do
      conn = get(conn, Routes.holiday_or_vacation_type_path(conn, :new))
      assert html_response(conn, 200) =~ "New Holiday or vacation type"
    end

    test "shows form for editing chosen holiday_or_vacation_type", %{conn: conn} do
      holiday_or_vacation_type = insert(:holiday_or_vacation_type)

      conn =
        get(conn, Routes.holiday_or_vacation_type_path(conn, :edit, holiday_or_vacation_type))

      assert html_response(conn, 200) =~ "Edit Holiday or vacation type"
    end
  end

  describe "create holiday_or_vacation_type" do
    test "redirects to show when data is valid", %{conn: conn} do
      country = insert(:country)
      create_attrs = Map.put(@create_attrs, :country_location_id, country.id)

      conn =
        post(conn, Routes.holiday_or_vacation_type_path(conn, :create),
          holiday_or_vacation_type: create_attrs
        )

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.holiday_or_vacation_type_path(conn, :show, id)

      conn = get(conn, Routes.holiday_or_vacation_type_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Holiday or vacation type"
      assert Calendars.get_holiday_or_vacation_type!(id)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.holiday_or_vacation_type_path(conn, :create),
          holiday_or_vacation_type: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "New Holiday or vacation type"
    end
  end

  describe "update holiday_or_vacation_type" do
    setup [:create_holiday_or_vacation_type]

    test "redirects when data is valid", %{
      conn: conn,
      holiday_or_vacation_type: holiday_or_vacation_type
    } do
      conn =
        put(conn, Routes.holiday_or_vacation_type_path(conn, :update, holiday_or_vacation_type),
          holiday_or_vacation_type: @update_attrs
        )

      assert redirected_to(conn) ==
               Routes.holiday_or_vacation_type_path(conn, :show, holiday_or_vacation_type)

      conn =
        get(conn, Routes.holiday_or_vacation_type_path(conn, :show, holiday_or_vacation_type))

      assert html_response(conn, 200) =~ "blue"

      holiday_or_vacation_type =
        Calendars.get_holiday_or_vacation_type!(holiday_or_vacation_type.id)

      assert holiday_or_vacation_type.default_is_listed_below_month == false
      assert holiday_or_vacation_type.default_is_school_vacation == false
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      holiday_or_vacation_type: holiday_or_vacation_type
    } do
      conn =
        put(conn, Routes.holiday_or_vacation_type_path(conn, :update, holiday_or_vacation_type),
          holiday_or_vacation_type: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Holiday or vacation type"
    end
  end

  describe "delete holiday_or_vacation_type" do
    setup [:create_holiday_or_vacation_type]

    test "deletes chosen holiday_or_vacation_type", %{
      conn: conn,
      holiday_or_vacation_type: holiday_or_vacation_type
    } do
      conn =
        delete(
          conn,
          Routes.holiday_or_vacation_type_path(conn, :delete, holiday_or_vacation_type)
        )

      assert redirected_to(conn) == Routes.holiday_or_vacation_type_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.holiday_or_vacation_type_path(conn, :show, holiday_or_vacation_type))
      end
    end
  end

  defp create_holiday_or_vacation_type(_) do
    holiday_or_vacation_type = insert(:holiday_or_vacation_type)
    {:ok, holiday_or_vacation_type: holiday_or_vacation_type}
  end
end
