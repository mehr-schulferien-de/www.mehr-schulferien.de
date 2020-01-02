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
end
