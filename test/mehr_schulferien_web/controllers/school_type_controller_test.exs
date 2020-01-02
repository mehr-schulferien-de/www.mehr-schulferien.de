defmodule MehrSchulferienWeb.SchoolTypeControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Institutions

  @create_attrs %{name: "some name", slug: "some slug"}
  @update_attrs %{name: "some updated name", slug: "some updated slug"}
  @invalid_attrs %{name: nil, slug: nil}

  def fixture(:school_type) do
    {:ok, school_type} = Institutions.create_school_type(@create_attrs)
    school_type
  end

  describe "index" do
    test "lists all school_types", %{conn: conn} do
      conn = get(conn, Routes.school_type_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing School types"
    end
  end

  describe "new school_type" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.school_type_path(conn, :new))
      assert html_response(conn, 200) =~ "New School type"
    end
  end

  describe "create school_type" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.school_type_path(conn, :create), school_type: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.school_type_path(conn, :show, id)

      conn = get(conn, Routes.school_type_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show School type"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.school_type_path(conn, :create), school_type: @invalid_attrs)
      assert html_response(conn, 200) =~ "New School type"
    end
  end

  describe "edit school_type" do
    setup [:create_school_type]

    test "renders form for editing chosen school_type", %{conn: conn, school_type: school_type} do
      conn = get(conn, Routes.school_type_path(conn, :edit, school_type))
      assert html_response(conn, 200) =~ "Edit School type"
    end
  end

  describe "update school_type" do
    setup [:create_school_type]

    test "redirects when data is valid", %{conn: conn, school_type: school_type} do
      conn = put(conn, Routes.school_type_path(conn, :update, school_type), school_type: @update_attrs)
      assert redirected_to(conn) == Routes.school_type_path(conn, :show, school_type)

      conn = get(conn, Routes.school_type_path(conn, :show, school_type))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, school_type: school_type} do
      conn = put(conn, Routes.school_type_path(conn, :update, school_type), school_type: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit School type"
    end
  end

  describe "delete school_type" do
    setup [:create_school_type]

    test "deletes chosen school_type", %{conn: conn, school_type: school_type} do
      conn = delete(conn, Routes.school_type_path(conn, :delete, school_type))
      assert redirected_to(conn) == Routes.school_type_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.school_type_path(conn, :show, school_type))
      end
    end
  end

  defp create_school_type(_) do
    school_type = fixture(:school_type)
    {:ok, school_type: school_type}
  end
end
