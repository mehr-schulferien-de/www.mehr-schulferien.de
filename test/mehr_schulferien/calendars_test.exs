defmodule MehrSchulferien.CalendarsTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.Calendars
  alias MehrSchulferien.Calendars.{HolidayOrVacationType, Period, Religion}

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

  describe "periods" do
    @valid_attrs %{
      "created_by_email_address" => "george@example.com",
      "ends_on" => ~D[2010-04-20],
      "starts_on" => ~D[2010-04-17]
    }
    @update_attrs %{
      "html_class" => "white",
      "is_public_holiday" => true
    }
    @invalid_attrs %{
      "created_by_email_address" => "george@example.com",
      "ends_on" => ~D[2010-04-20],
      "starts_on" => ~D[2010-04-27]
    }

    test "list_periods/0 returns all periods" do
      period = insert(:period)
      assert [period_1] = Calendars.list_periods()
      assert period.id == period_1.id
    end

    test "get_period!/1 returns the period with given id" do
      period = insert(:period)
      assert period_1 = Calendars.get_period!(period.id)
      assert period.id == period_1.id
    end

    test "create_period/1 with valid data creates a period" do
      location = insert(:federal_state)
      holiday_or_vacation_type = insert(:holiday_or_vacation_type)

      valid_attrs =
        Map.merge(@valid_attrs, %{
          "holiday_or_vacation_type_id" => holiday_or_vacation_type.id,
          "location_id" => location.id
        })

      assert {:ok, %Period{} = period} = Calendars.create_period(valid_attrs)

      assert period.created_by_email_address == "george@example.com"
      assert period.ends_on == ~D[2010-04-20]
      assert period.starts_on == ~D[2010-04-17]
      assert period.html_class == holiday_or_vacation_type.default_html_class
      assert period.is_public_holiday == holiday_or_vacation_type.default_is_public_holiday
      assert period.religion_id == holiday_or_vacation_type.default_religion_id
    end

    test "create_period/1 with attrs overriding holiday_or_vacation_type defaults" do
      location = insert(:federal_state)
      holiday_or_vacation_type = insert(:holiday_or_vacation_type)

      valid_attrs =
        Map.merge(@valid_attrs, %{
          "location_id" => location.id,
          "holiday_or_vacation_type_id" => holiday_or_vacation_type.id,
          "is_public_holiday" => !holiday_or_vacation_type.default_is_public_holiday
        })

      assert {:ok, %Period{} = period} = Calendars.create_period(valid_attrs)
      assert period.created_by_email_address == "george@example.com"
      assert period.is_public_holiday != holiday_or_vacation_type.default_is_public_holiday
    end

    test "create_period/1 with invalid data returns error changeset" do
      location = insert(:federal_state)
      holiday_or_vacation_type = insert(:holiday_or_vacation_type)

      invalid_attrs =
        Map.merge(@invalid_attrs, %{
          "holiday_or_vacation_type_id" => holiday_or_vacation_type.id,
          "location_id" => location.id
        })

      assert {:error, %Ecto.Changeset{} = changeset} = Calendars.create_period(invalid_attrs)

      assert %{starts_on: ["starts_on should be less than or equal to ends_on"]} =
               errors_on(changeset)

      invalid_attrs = Map.put(invalid_attrs, "ends_on", nil)
      assert {:error, %Ecto.Changeset{} = changeset} = Calendars.create_period(invalid_attrs)
      assert %{ends_on: ["can't be blank"]} = errors_on(changeset)
    end

    test "update_period/2 with valid data updates the period" do
      period = insert(:period)
      assert {:ok, %Period{} = period} = Calendars.update_period(period, @update_attrs)
      assert period.html_class == "white"
      assert period.is_public_holiday == true
    end

    test "update_period/2 with invalid data returns error changeset" do
      period = insert(:period)
      assert {:error, %Ecto.Changeset{}} = Calendars.update_period(period, @invalid_attrs)
    end

    test "delete_period/1 deletes the period" do
      period = insert(:period)
      assert {:ok, %Period{}} = Calendars.delete_period(period)
      assert_raise Ecto.NoResultsError, fn -> Calendars.get_period!(period.id) end
    end

    test "change_period/1 returns a period changeset" do
      period = insert(:period)
      assert %Ecto.Changeset{} = Calendars.change_period(period)
    end

    test "find_period/2 returns period if the date is a holiday" do
      period_1 = insert(:period, %{starts_on: ~D[2020-02-04], ends_on: ~D[2020-02-07]})
      period_2 = insert(:period, %{starts_on: ~D[2020-04-04], ends_on: ~D[2020-04-07]})
      periods = Calendars.list_periods()
      refute Calendars.find_period(~D[2020-02-03], periods)
      assert %Period{id: id} = Calendars.find_period(~D[2020-02-04], periods)
      assert id == period_1.id
      assert Calendars.find_period(~D[2020-02-06], periods)
      assert Calendars.find_period(~D[2020-02-07], periods)
      assert %Period{id: id} = Calendars.find_period(~D[2020-04-04], periods)
      assert id == period_2.id
      assert Calendars.find_period(~D[2020-04-06], periods)
      assert Calendars.find_period(~D[2020-04-07], periods)
      refute Calendars.find_period(~D[2020-04-08], periods)
    end

    test "find_periods_by_month/2 returns periods if the month has a holiday" do
      _period_1 = insert(:period, %{starts_on: ~D[2020-02-04], ends_on: ~D[2020-02-07]})
      _period_2 = insert(:period, %{starts_on: ~D[2020-02-24], ends_on: ~D[2020-02-27]})
      period_3 = insert(:period, %{starts_on: ~D[2020-04-04], ends_on: ~D[2020-06-07]})
      periods = Calendars.list_periods()
      assert Calendars.find_periods_by_month(~D[2020-01-01], periods) == []
      assert length(Calendars.find_periods_by_month(~D[2020-02-01], periods)) == 2
      assert [%Period{id: id}] = Calendars.find_periods_by_month(~D[2020-04-01], periods)
      assert id == period_3.id
      assert [%Period{id: ^id}] = Calendars.find_periods_by_month(~D[2020-05-01], periods)
      assert [%Period{id: ^id}] = Calendars.find_periods_by_month(~D[2020-06-01], periods)
      assert Calendars.find_periods_by_month(~D[2020-08-01], periods) == []
    end
  end
end
