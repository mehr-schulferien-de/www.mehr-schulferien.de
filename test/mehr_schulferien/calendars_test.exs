defmodule MehrSchulferien.CalendarsTest do
  use MehrSchulferien.DataCase

  alias MehrSchulferien.Calendars

  describe "religions" do
    alias MehrSchulferien.Calendars.Religion

    @valid_attrs %{name: "some name", slug: "some slug", wikipedia_url: "some wikipedia_url"}
    @update_attrs %{name: "some updated name", slug: "some updated slug", wikipedia_url: "some updated wikipedia_url"}
    @invalid_attrs %{name: nil, slug: nil, wikipedia_url: nil}

    def religion_fixture(attrs \\ %{}) do
      {:ok, religion} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Calendars.create_religion()

      religion
    end

    test "list_religions/0 returns all religions" do
      religion = religion_fixture()
      assert Calendars.list_religions() == [religion]
    end

    test "get_religion!/1 returns the religion with given id" do
      religion = religion_fixture()
      assert Calendars.get_religion!(religion.id) == religion
    end

    test "create_religion/1 with valid data creates a religion" do
      assert {:ok, %Religion{} = religion} = Calendars.create_religion(@valid_attrs)
      assert religion.name == "some name"
      assert religion.slug == "some slug"
      assert religion.wikipedia_url == "some wikipedia_url"
    end

    test "create_religion/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Calendars.create_religion(@invalid_attrs)
    end

    test "update_religion/2 with valid data updates the religion" do
      religion = religion_fixture()
      assert {:ok, %Religion{} = religion} = Calendars.update_religion(religion, @update_attrs)
      assert religion.name == "some updated name"
      assert religion.slug == "some updated slug"
      assert religion.wikipedia_url == "some updated wikipedia_url"
    end

    test "update_religion/2 with invalid data returns error changeset" do
      religion = religion_fixture()
      assert {:error, %Ecto.Changeset{}} = Calendars.update_religion(religion, @invalid_attrs)
      assert religion == Calendars.get_religion!(religion.id)
    end

    test "delete_religion/1 deletes the religion" do
      religion = religion_fixture()
      assert {:ok, %Religion{}} = Calendars.delete_religion(religion)
      assert_raise Ecto.NoResultsError, fn -> Calendars.get_religion!(religion.id) end
    end

    test "change_religion/1 returns a religion changeset" do
      religion = religion_fixture()
      assert %Ecto.Changeset{} = Calendars.change_religion(religion)
    end
  end
end
