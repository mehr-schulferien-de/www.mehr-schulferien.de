defmodule MehrSchulferien.InstitutionsTest do
  use MehrSchulferien.DataCase

  alias MehrSchulferien.Institutions

  describe "school_types" do
    alias MehrSchulferien.Institutions.SchoolType

    @valid_attrs %{name: "some name", slug: "some slug"}
    @update_attrs %{name: "some updated name", slug: "some updated slug"}
    @invalid_attrs %{name: nil, slug: nil}

    def school_type_fixture(attrs \\ %{}) do
      {:ok, school_type} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Institutions.create_school_type()

      school_type
    end

    test "list_school_types/0 returns all school_types" do
      school_type = school_type_fixture()
      assert Institutions.list_school_types() == [school_type]
    end

    test "get_school_type!/1 returns the school_type with given id" do
      school_type = school_type_fixture()
      assert Institutions.get_school_type!(school_type.id) == school_type
    end

    test "create_school_type/1 with valid data creates a school_type" do
      assert {:ok, %SchoolType{} = school_type} = Institutions.create_school_type(@valid_attrs)
      assert school_type.name == "some name"
      assert school_type.slug == "some slug"
    end

    test "create_school_type/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Institutions.create_school_type(@invalid_attrs)
    end

    test "update_school_type/2 with valid data updates the school_type" do
      school_type = school_type_fixture()
      assert {:ok, %SchoolType{} = school_type} = Institutions.update_school_type(school_type, @update_attrs)
      assert school_type.name == "some updated name"
      assert school_type.slug == "some updated slug"
    end

    test "update_school_type/2 with invalid data returns error changeset" do
      school_type = school_type_fixture()
      assert {:error, %Ecto.Changeset{}} = Institutions.update_school_type(school_type, @invalid_attrs)
      assert school_type == Institutions.get_school_type!(school_type.id)
    end

    test "delete_school_type/1 deletes the school_type" do
      school_type = school_type_fixture()
      assert {:ok, %SchoolType{}} = Institutions.delete_school_type(school_type)
      assert_raise Ecto.NoResultsError, fn -> Institutions.get_school_type!(school_type.id) end
    end

    test "change_school_type/1 returns a school_type changeset" do
      school_type = school_type_fixture()
      assert %Ecto.Changeset{} = Institutions.change_school_type(school_type)
    end
  end

  describe "schools" do
    alias MehrSchulferien.Institutions.School

    @valid_attrs %{email_address: "some email_address", fax_number: "some fax_number", homepage_url: "some homepage_url", lat: 120.5, line1: "some line1", line2: "some line2", lon: 120.5, memo: "some memo", name: "some name", number_of_students: 42, phone_number: "some phone_number", slug: "some slug", street: "some street", zip_code: "some zip_code"}
    @update_attrs %{email_address: "some updated email_address", fax_number: "some updated fax_number", homepage_url: "some updated homepage_url", lat: 456.7, line1: "some updated line1", line2: "some updated line2", lon: 456.7, memo: "some updated memo", name: "some updated name", number_of_students: 43, phone_number: "some updated phone_number", slug: "some updated slug", street: "some updated street", zip_code: "some updated zip_code"}
    @invalid_attrs %{email_address: nil, fax_number: nil, homepage_url: nil, lat: nil, line1: nil, line2: nil, lon: nil, memo: nil, name: nil, number_of_students: nil, phone_number: nil, slug: nil, street: nil, zip_code: nil}

    def school_fixture(attrs \\ %{}) do
      {:ok, school} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Institutions.create_school()

      school
    end

    test "list_schools/0 returns all schools" do
      school = school_fixture()
      assert Institutions.list_schools() == [school]
    end

    test "get_school!/1 returns the school with given id" do
      school = school_fixture()
      assert Institutions.get_school!(school.id) == school
    end

    test "create_school/1 with valid data creates a school" do
      assert {:ok, %School{} = school} = Institutions.create_school(@valid_attrs)
      assert school.email_address == "some email_address"
      assert school.fax_number == "some fax_number"
      assert school.homepage_url == "some homepage_url"
      assert school.lat == 120.5
      assert school.line1 == "some line1"
      assert school.line2 == "some line2"
      assert school.lon == 120.5
      assert school.memo == "some memo"
      assert school.name == "some name"
      assert school.number_of_students == 42
      assert school.phone_number == "some phone_number"
      assert school.slug == "some slug"
      assert school.street == "some street"
      assert school.zip_code == "some zip_code"
    end

    test "create_school/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Institutions.create_school(@invalid_attrs)
    end

    test "update_school/2 with valid data updates the school" do
      school = school_fixture()
      assert {:ok, %School{} = school} = Institutions.update_school(school, @update_attrs)
      assert school.email_address == "some updated email_address"
      assert school.fax_number == "some updated fax_number"
      assert school.homepage_url == "some updated homepage_url"
      assert school.lat == 456.7
      assert school.line1 == "some updated line1"
      assert school.line2 == "some updated line2"
      assert school.lon == 456.7
      assert school.memo == "some updated memo"
      assert school.name == "some updated name"
      assert school.number_of_students == 43
      assert school.phone_number == "some updated phone_number"
      assert school.slug == "some updated slug"
      assert school.street == "some updated street"
      assert school.zip_code == "some updated zip_code"
    end

    test "update_school/2 with invalid data returns error changeset" do
      school = school_fixture()
      assert {:error, %Ecto.Changeset{}} = Institutions.update_school(school, @invalid_attrs)
      assert school == Institutions.get_school!(school.id)
    end

    test "delete_school/1 deletes the school" do
      school = school_fixture()
      assert {:ok, %School{}} = Institutions.delete_school(school)
      assert_raise Ecto.NoResultsError, fn -> Institutions.get_school!(school.id) end
    end

    test "change_school/1 returns a school changeset" do
      school = school_fixture()
      assert %Ecto.Changeset{} = Institutions.change_school(school)
    end
  end
end
