defmodule MehrSchulferien.CalendarsTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.Calendars
  alias MehrSchulferien.Calendars.{HolidayOrVacationType, Religion}

  describe "religions" do
    @valid_attrs %{
      name: "Christentum",
      wikipedia_url: "https://de.wikipedia.org/wiki/Christentum"
    }
    @update_attrs %{wikipedia_url: "https://de.m.wikipedia.org/wiki/Christentum"}
    @invalid_attrs %{name: nil}

    test "list_religions/0 returns all religions" do
      religion = insert(:religion)
      assert Calendars.list_religions() == [religion]
    end

    test "get_religion!/1 returns the religion with given id" do
      religion = insert(:religion)
      assert Calendars.get_religion!(religion.id) == religion
    end

    test "create_religion/1 with valid data creates a religion" do
      assert {:ok, %Religion{} = religion} = Calendars.create_religion(@valid_attrs)
      assert religion.name == "Christentum"
      assert religion.slug == "christentum"
      assert religion.wikipedia_url == "https://de.wikipedia.org/wiki/Christentum"
    end

    test "create_religion/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Calendars.create_religion(@invalid_attrs)
    end

    test "update_religion/2 with valid data updates the religion" do
      religion = insert(:religion)
      assert {:ok, %Religion{} = religion} = Calendars.update_religion(religion, @update_attrs)
      assert religion.wikipedia_url == "https://de.m.wikipedia.org/wiki/Christentum"
    end

    test "update_religion/2 with invalid data returns error changeset" do
      religion = insert(:religion)
      assert {:error, %Ecto.Changeset{}} = Calendars.update_religion(religion, @invalid_attrs)
      assert religion == Calendars.get_religion!(religion.id)
    end

    test "delete_religion/1 deletes the religion" do
      religion = insert(:religion)
      assert {:ok, %Religion{}} = Calendars.delete_religion(religion)
      assert_raise Ecto.NoResultsError, fn -> Calendars.get_religion!(religion.id) end
    end

    test "change_religion/1 returns a religion changeset" do
      religion = insert(:religion)
      assert %Ecto.Changeset{} = Calendars.change_religion(religion)
    end
  end

  describe "holiday_or_vacation_types" do
    @valid_attrs %{
      colloquial: "Weihnachtsferien",
      default_display_priority: 4,
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

    test "list_holiday_or_vacation_types/0 returns all holiday_or_vacation_types" do
      holiday_or_vacation_type = insert(:holiday_or_vacation_type)
      assert Calendars.list_holiday_or_vacation_types() == [holiday_or_vacation_type]
    end

    test "get_holiday_or_vacation_type!/1 returns the holiday_or_vacation_type with given id" do
      holiday_or_vacation_type = insert(:holiday_or_vacation_type)

      assert Calendars.get_holiday_or_vacation_type!(holiday_or_vacation_type.id) ==
               holiday_or_vacation_type
    end

    test "create_holiday_or_vacation_type/1 with valid data creates a holiday_or_vacation_type" do
      country = insert(:country)
      valid_attrs = Map.put(@valid_attrs, :country_location_id, country.id)

      assert {:ok, %HolidayOrVacationType{} = holiday_or_vacation_type} =
               Calendars.create_holiday_or_vacation_type(valid_attrs)

      assert holiday_or_vacation_type.colloquial == "Weihnachtsferien"
      assert holiday_or_vacation_type.default_html_class == "green"
      assert holiday_or_vacation_type.default_is_listed_below_month == true
      assert holiday_or_vacation_type.default_is_public_holiday == false
      assert holiday_or_vacation_type.default_is_school_vacation == true
      assert holiday_or_vacation_type.default_is_valid_for_everybody == false
      assert holiday_or_vacation_type.default_is_valid_for_students == true
      assert holiday_or_vacation_type.name == "Weihnachten"
      assert holiday_or_vacation_type.slug == "weihnachten"

      assert holiday_or_vacation_type.wikipedia_url ==
               "https://de.wikipedia.org/wiki/Schulferien#Weihnachtsferien"
    end

    test "create_holiday_or_vacation_type/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Calendars.create_holiday_or_vacation_type(@invalid_attrs)
    end

    test "update_holiday_or_vacation_type/2 with valid data updates the holiday_or_vacation_type" do
      holiday_or_vacation_type = insert(:holiday_or_vacation_type)

      assert {:ok, %HolidayOrVacationType{} = holiday_or_vacation_type} =
               Calendars.update_holiday_or_vacation_type(holiday_or_vacation_type, @update_attrs)

      assert holiday_or_vacation_type.default_html_class == "blue"
      assert holiday_or_vacation_type.default_is_listed_below_month == false
      assert holiday_or_vacation_type.default_is_school_vacation == false
    end

    test "update_holiday_or_vacation_type/2 with invalid data returns error changeset" do
      holiday_or_vacation_type = insert(:holiday_or_vacation_type)

      assert {:error, %Ecto.Changeset{}} =
               Calendars.update_holiday_or_vacation_type(holiday_or_vacation_type, @invalid_attrs)

      assert holiday_or_vacation_type ==
               Calendars.get_holiday_or_vacation_type!(holiday_or_vacation_type.id)
    end

    test "delete_holiday_or_vacation_type/1 deletes the holiday_or_vacation_type" do
      holiday_or_vacation_type = insert(:holiday_or_vacation_type)

      assert {:ok, %HolidayOrVacationType{}} =
               Calendars.delete_holiday_or_vacation_type(holiday_or_vacation_type)

      assert_raise Ecto.NoResultsError, fn ->
        Calendars.get_holiday_or_vacation_type!(holiday_or_vacation_type.id)
      end
    end

    test "change_holiday_or_vacation_type/1 returns a holiday_or_vacation_type changeset" do
      holiday_or_vacation_type = insert(:holiday_or_vacation_type)

      assert %Ecto.Changeset{} =
               Calendars.change_holiday_or_vacation_type(holiday_or_vacation_type)
    end
  end
end
