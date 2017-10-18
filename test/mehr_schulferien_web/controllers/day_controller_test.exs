defmodule MehrSchulferienWeb.DayControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Timetables

  @create_attrs %{calendar_week: 42, day_of_month: 42, day_of_year: 42, slug: "some slug", value: ~D[2010-04-17], weekday: 42, weekday_de: "some weekday_de"}
  @update_attrs %{calendar_week: 43, day_of_month: 43, day_of_year: 43, slug: "some updated slug", value: ~D[2011-05-18], weekday: 43, weekday_de: "some updated weekday_de"}
  @invalid_attrs %{calendar_week: nil, day_of_month: nil, day_of_year: nil, slug: nil, value: nil, weekday: nil, weekday_de: nil}

  def fixture(:day) do
    {:ok, day} = Timetables.create_day(@create_attrs)
    day
  end

  describe "index" do
    test "lists all days", %{conn: conn} do
      conn = get conn, day_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Days"
    end
  end

  describe "new day" do
    test "renders form", %{conn: conn} do
      conn = get conn, day_path(conn, :new)
      assert html_response(conn, 200) =~ "New Day"
    end
  end

  describe "create day" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, day_path(conn, :create), day: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == day_path(conn, :show, id)

      conn = get conn, day_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Day"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, day_path(conn, :create), day: @invalid_attrs
      assert html_response(conn, 200) =~ "New Day"
    end
  end

  describe "edit day" do
    setup [:create_day]

    test "renders form for editing chosen day", %{conn: conn, day: day} do
      conn = get conn, day_path(conn, :edit, day)
      assert html_response(conn, 200) =~ "Edit Day"
    end
  end

  describe "update day" do
    setup [:create_day]

    test "redirects when data is valid", %{conn: conn, day: day} do
      conn = put conn, day_path(conn, :update, day), day: @update_attrs
      assert redirected_to(conn) == day_path(conn, :show, day)

      conn = get conn, day_path(conn, :show, day)
      assert html_response(conn, 200) =~ "some updated slug"
    end

    test "renders errors when data is invalid", %{conn: conn, day: day} do
      conn = put conn, day_path(conn, :update, day), day: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Day"
    end
  end

  describe "delete day" do
    setup [:create_day]

    test "deletes chosen day", %{conn: conn, day: day} do
      conn = delete conn, day_path(conn, :delete, day)
      assert redirected_to(conn) == day_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, day_path(conn, :show, day)
      end
    end
  end

  defp create_day(_) do
    day = fixture(:day)
    {:ok, day: day}
  end
end
