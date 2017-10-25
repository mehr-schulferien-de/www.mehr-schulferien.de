defmodule MehrSchulferienWeb.SchoolControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Locations

  @create_attrs %{address_city: "some address_city", address_line1: "some address_line1", address_line2: "some address_line2", address_street: "some address_street", address_zip_code: "some address_zip_code", email_address: "some email_address", fax_number: "some fax_number", homepage_url: "some homepage_url", name: "some name", phone_number: "some phone_number", slug: "some slug"}
  @update_attrs %{address_city: "some updated address_city", address_line1: "some updated address_line1", address_line2: "some updated address_line2", address_street: "some updated address_street", address_zip_code: "some updated address_zip_code", email_address: "some updated email_address", fax_number: "some updated fax_number", homepage_url: "some updated homepage_url", name: "some updated name", phone_number: "some updated phone_number", slug: "some updated slug"}
  @invalid_attrs %{address_city: nil, address_line1: nil, address_line2: nil, address_street: nil, address_zip_code: nil, email_address: nil, fax_number: nil, homepage_url: nil, name: nil, phone_number: nil, slug: nil}

  def fixture(:school) do
    {:ok, school} = Locations.create_school(@create_attrs)
    school
  end

  describe "index" do
    test "lists all schools", %{conn: conn} do
      conn = get conn, school_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Schools"
    end
  end

  describe "new school" do
    test "renders form", %{conn: conn} do
      conn = get conn, school_path(conn, :new)
      assert html_response(conn, 200) =~ "New School"
    end
  end

  describe "create school" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, school_path(conn, :create), school: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == school_path(conn, :show, id)

      conn = get conn, school_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show School"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, school_path(conn, :create), school: @invalid_attrs
      assert html_response(conn, 200) =~ "New School"
    end
  end

  describe "edit school" do
    setup [:create_school]

    test "renders form for editing chosen school", %{conn: conn, school: school} do
      conn = get conn, school_path(conn, :edit, school)
      assert html_response(conn, 200) =~ "Edit School"
    end
  end

  describe "update school" do
    setup [:create_school]

    test "redirects when data is valid", %{conn: conn, school: school} do
      conn = put conn, school_path(conn, :update, school), school: @update_attrs
      assert redirected_to(conn) == school_path(conn, :show, school)

      conn = get conn, school_path(conn, :show, school)
      assert html_response(conn, 200) =~ "some updated address_city"
    end

    test "renders errors when data is invalid", %{conn: conn, school: school} do
      conn = put conn, school_path(conn, :update, school), school: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit School"
    end
  end

  describe "delete school" do
    setup [:create_school]

    test "deletes chosen school", %{conn: conn, school: school} do
      conn = delete conn, school_path(conn, :delete, school)
      assert redirected_to(conn) == school_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, school_path(conn, :show, school)
      end
    end
  end

  defp create_school(_) do
    school = fixture(:school)
    {:ok, school: school}
  end
end
