defmodule MehrSchulferienWeb.Api.SchoolControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.School

  @create_attrs %{address_city: "some address_city", address_line1: "some address_line1", address_street: "some address_street", address_zip_code: "some address_zip_code", city_id: 42, country_id: 42, email_address: "some email_address", fax_number: "some fax_number", federal_state_id: 42, homepage_url: "some homepage_url", name: "some name", phone_number: "some phone_number", slug: "some slug"}
  @update_attrs %{address_city: "some updated address_city", address_line1: "some updated address_line1", address_street: "some updated address_street", address_zip_code: "some updated address_zip_code", city_id: 43, country_id: 43, email_address: "some updated email_address", fax_number: "some updated fax_number", federal_state_id: 43, homepage_url: "some updated homepage_url", name: "some updated name", phone_number: "some updated phone_number", slug: "some updated slug"}
  @invalid_attrs %{address_city: nil, address_line1: nil, address_street: nil, address_zip_code: nil, city_id: nil, country_id: nil, email_address: nil, fax_number: nil, federal_state_id: nil, homepage_url: nil, name: nil, phone_number: nil, slug: nil}

  def fixture(:school) do
    {:ok, school} = Locations.create_school(@create_attrs)
    school
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all schools", %{conn: conn} do
      conn = get conn, api_school_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create school" do
    test "renders school when data is valid", %{conn: conn} do
      conn = post conn, api_school_path(conn, :create), school: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, api_school_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "address_city" => "some address_city",
        "address_line1" => "some address_line1",
        "address_street" => "some address_street",
        "address_zip_code" => "some address_zip_code",
        "city_id" => 42,
        "country_id" => 42,
        "email_address" => "some email_address",
        "fax_number" => "some fax_number",
        "federal_state_id" => 42,
        "homepage_url" => "some homepage_url",
        "name" => "some name",
        "phone_number" => "some phone_number",
        "slug" => "some slug"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, api_school_path(conn, :create), school: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update school" do
    setup [:create_school]

    test "renders school when data is valid", %{conn: conn, school: %School{id: id} = school} do
      conn = put conn, api_school_path(conn, :update, school), school: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, api_school_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "address_city" => "some updated address_city",
        "address_line1" => "some updated address_line1",
        "address_street" => "some updated address_street",
        "address_zip_code" => "some updated address_zip_code",
        "city_id" => 43,
        "country_id" => 43,
        "email_address" => "some updated email_address",
        "fax_number" => "some updated fax_number",
        "federal_state_id" => 43,
        "homepage_url" => "some updated homepage_url",
        "name" => "some updated name",
        "phone_number" => "some updated phone_number",
        "slug" => "some updated slug"}
    end

    test "renders errors when data is invalid", %{conn: conn, school: school} do
      conn = put conn, api_school_path(conn, :update, school), school: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete school" do
    setup [:create_school]

    test "deletes chosen school", %{conn: conn, school: school} do
      conn = delete conn, api_school_path(conn, :delete, school)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, api_school_path(conn, :show, school)
      end
    end
  end

  defp create_school(_) do
    school = fixture(:school)
    {:ok, school: school}
  end
end
