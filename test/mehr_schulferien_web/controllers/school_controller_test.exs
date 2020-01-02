defmodule MehrSchulferienWeb.SchoolControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Institutions

  @create_attrs %{email_address: "some email_address", fax_number: "some fax_number", homepage_url: "some homepage_url", lat: 120.5, line1: "some line1", line2: "some line2", lon: 120.5, memo: "some memo", name: "some name", number_of_students: 42, phone_number: "some phone_number", slug: "some slug", street: "some street", zip_code: "some zip_code"}
  @update_attrs %{email_address: "some updated email_address", fax_number: "some updated fax_number", homepage_url: "some updated homepage_url", lat: 456.7, line1: "some updated line1", line2: "some updated line2", lon: 456.7, memo: "some updated memo", name: "some updated name", number_of_students: 43, phone_number: "some updated phone_number", slug: "some updated slug", street: "some updated street", zip_code: "some updated zip_code"}
  @invalid_attrs %{email_address: nil, fax_number: nil, homepage_url: nil, lat: nil, line1: nil, line2: nil, lon: nil, memo: nil, name: nil, number_of_students: nil, phone_number: nil, slug: nil, street: nil, zip_code: nil}

  def fixture(:school) do
    {:ok, school} = Institutions.create_school(@create_attrs)
    school
  end

  describe "index" do
    test "lists all schools", %{conn: conn} do
      conn = get(conn, Routes.school_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Schools"
    end
  end

  describe "new school" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.school_path(conn, :new))
      assert html_response(conn, 200) =~ "New School"
    end
  end

  describe "create school" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.school_path(conn, :create), school: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.school_path(conn, :show, id)

      conn = get(conn, Routes.school_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show School"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.school_path(conn, :create), school: @invalid_attrs)
      assert html_response(conn, 200) =~ "New School"
    end
  end

  describe "edit school" do
    setup [:create_school]

    test "renders form for editing chosen school", %{conn: conn, school: school} do
      conn = get(conn, Routes.school_path(conn, :edit, school))
      assert html_response(conn, 200) =~ "Edit School"
    end
  end

  describe "update school" do
    setup [:create_school]

    test "redirects when data is valid", %{conn: conn, school: school} do
      conn = put(conn, Routes.school_path(conn, :update, school), school: @update_attrs)
      assert redirected_to(conn) == Routes.school_path(conn, :show, school)

      conn = get(conn, Routes.school_path(conn, :show, school))
      assert html_response(conn, 200) =~ "some updated email_address"
    end

    test "renders errors when data is invalid", %{conn: conn, school: school} do
      conn = put(conn, Routes.school_path(conn, :update, school), school: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit School"
    end
  end

  describe "delete school" do
    setup [:create_school]

    test "deletes chosen school", %{conn: conn, school: school} do
      conn = delete(conn, Routes.school_path(conn, :delete, school))
      assert redirected_to(conn) == Routes.school_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.school_path(conn, :show, school))
      end
    end
  end

  defp create_school(_) do
    school = fixture(:school)
    {:ok, school: school}
  end
end
