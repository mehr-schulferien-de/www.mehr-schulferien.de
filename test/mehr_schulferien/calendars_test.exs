defmodule MehrSchulferien.CalendarsTest do
  use MehrSchulferien.DataCase

  alias MehrSchulferien.Calendars

  describe "religions" do
    alias MehrSchulferien.Calendars.Religion

    @valid_attrs %{name: "some name", slug: "some slug", wikipedia_url: "some wikipedia_url"}
    @update_attrs %{
      name: "some updated name",
      slug: "some updated slug",
      wikipedia_url: "some updated wikipedia_url"
    }
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

  describe "holiday_or_vacation_types" do
    alias MehrSchulferien.Calendars.HolidayOrVacationType

    @valid_attrs %{
      colloquial: "some colloquial",
      display_priority: 42,
      html_class: "some html_class",
      listed_below_month: true,
      name: "some name",
      needs_approval: true,
      public_holiday: true,
      school_vacation: true,
      slug: "some slug",
      valid_for_everybody: true,
      valid_for_students: true,
      wikipedia_url: "some wikipedia_url"
    }
    @update_attrs %{
      colloquial: "some updated colloquial",
      display_priority: 43,
      html_class: "some updated html_class",
      listed_below_month: false,
      name: "some updated name",
      needs_approval: false,
      public_holiday: false,
      school_vacation: false,
      slug: "some updated slug",
      valid_for_everybody: false,
      valid_for_students: false,
      wikipedia_url: "some updated wikipedia_url"
    }
    @invalid_attrs %{
      colloquial: nil,
      display_priority: nil,
      html_class: nil,
      listed_below_month: nil,
      name: nil,
      needs_approval: nil,
      public_holiday: nil,
      school_vacation: nil,
      slug: nil,
      valid_for_everybody: nil,
      valid_for_students: nil,
      wikipedia_url: nil
    }

    def holiday_or_vacation_type_fixture(attrs \\ %{}) do
      {:ok, holiday_or_vacation_type} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Calendars.create_holiday_or_vacation_type()

      holiday_or_vacation_type
    end

    test "list_holiday_or_vacation_types/0 returns all holiday_or_vacation_types" do
      holiday_or_vacation_type = holiday_or_vacation_type_fixture()
      assert Calendars.list_holiday_or_vacation_types() == [holiday_or_vacation_type]
    end

    test "get_holiday_or_vacation_type!/1 returns the holiday_or_vacation_type with given id" do
      holiday_or_vacation_type = holiday_or_vacation_type_fixture()

      assert Calendars.get_holiday_or_vacation_type!(holiday_or_vacation_type.id) ==
               holiday_or_vacation_type
    end

    test "create_holiday_or_vacation_type/1 with valid data creates a holiday_or_vacation_type" do
      assert {:ok, %HolidayOrVacationType{} = holiday_or_vacation_type} =
               Calendars.create_holiday_or_vacation_type(@valid_attrs)

      assert holiday_or_vacation_type.colloquial == "some colloquial"
      assert holiday_or_vacation_type.display_priority == 42
      assert holiday_or_vacation_type.html_class == "some html_class"
      assert holiday_or_vacation_type.listed_below_month == true
      assert holiday_or_vacation_type.name == "some name"
      assert holiday_or_vacation_type.needs_approval == true
      assert holiday_or_vacation_type.public_holiday == true
      assert holiday_or_vacation_type.school_vacation == true
      assert holiday_or_vacation_type.slug == "some slug"
      assert holiday_or_vacation_type.valid_for_everybody == true
      assert holiday_or_vacation_type.valid_for_students == true
      assert holiday_or_vacation_type.wikipedia_url == "some wikipedia_url"
    end

    test "create_holiday_or_vacation_type/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Calendars.create_holiday_or_vacation_type(@invalid_attrs)
    end

    test "update_holiday_or_vacation_type/2 with valid data updates the holiday_or_vacation_type" do
      holiday_or_vacation_type = holiday_or_vacation_type_fixture()

      assert {:ok, %HolidayOrVacationType{} = holiday_or_vacation_type} =
               Calendars.update_holiday_or_vacation_type(holiday_or_vacation_type, @update_attrs)

      assert holiday_or_vacation_type.colloquial == "some updated colloquial"
      assert holiday_or_vacation_type.display_priority == 43
      assert holiday_or_vacation_type.html_class == "some updated html_class"
      assert holiday_or_vacation_type.listed_below_month == false
      assert holiday_or_vacation_type.name == "some updated name"
      assert holiday_or_vacation_type.needs_approval == false
      assert holiday_or_vacation_type.public_holiday == false
      assert holiday_or_vacation_type.school_vacation == false
      assert holiday_or_vacation_type.slug == "some updated slug"
      assert holiday_or_vacation_type.valid_for_everybody == false
      assert holiday_or_vacation_type.valid_for_students == false
      assert holiday_or_vacation_type.wikipedia_url == "some updated wikipedia_url"
    end

    test "update_holiday_or_vacation_type/2 with invalid data returns error changeset" do
      holiday_or_vacation_type = holiday_or_vacation_type_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Calendars.update_holiday_or_vacation_type(holiday_or_vacation_type, @invalid_attrs)

      assert holiday_or_vacation_type ==
               Calendars.get_holiday_or_vacation_type!(holiday_or_vacation_type.id)
    end

    test "delete_holiday_or_vacation_type/1 deletes the holiday_or_vacation_type" do
      holiday_or_vacation_type = holiday_or_vacation_type_fixture()

      assert {:ok, %HolidayOrVacationType{}} =
               Calendars.delete_holiday_or_vacation_type(holiday_or_vacation_type)

      assert_raise Ecto.NoResultsError, fn ->
        Calendars.get_holiday_or_vacation_type!(holiday_or_vacation_type.id)
      end
    end

    test "change_holiday_or_vacation_type/1 returns a holiday_or_vacation_type changeset" do
      holiday_or_vacation_type = holiday_or_vacation_type_fixture()

      assert %Ecto.Changeset{} =
               Calendars.change_holiday_or_vacation_type(holiday_or_vacation_type)
    end
  end

  describe "periods" do
    alias MehrSchulferien.Calendars.Period

    @valid_attrs %{
      author_email_address: "some author_email_address",
      ends_on: ~D[2010-04-17],
      starts_on: ~D[2010-04-17]
    }
    @update_attrs %{
      author_email_address: "some updated author_email_address",
      ends_on: ~D[2011-05-18],
      starts_on: ~D[2011-05-18]
    }
    @invalid_attrs %{author_email_address: nil, ends_on: nil, starts_on: nil}

    def period_fixture(attrs \\ %{}) do
      {:ok, period} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Calendars.create_period()

      period
    end

    test "list_periods/0 returns all periods" do
      period = period_fixture()
      assert Calendars.list_periods() == [period]
    end

    test "get_period!/1 returns the period with given id" do
      period = period_fixture()
      assert Calendars.get_period!(period.id) == period
    end

    test "create_period/1 with valid data creates a period" do
      assert {:ok, %Period{} = period} = Calendars.create_period(@valid_attrs)
      assert period.author_email_address == "some author_email_address"
      assert period.ends_on == ~D[2010-04-17]
      assert period.starts_on == ~D[2010-04-17]
    end

    test "create_period/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Calendars.create_period(@invalid_attrs)
    end

    test "update_period/2 with valid data updates the period" do
      period = period_fixture()
      assert {:ok, %Period{} = period} = Calendars.update_period(period, @update_attrs)
      assert period.author_email_address == "some updated author_email_address"
      assert period.ends_on == ~D[2011-05-18]
      assert period.starts_on == ~D[2011-05-18]
    end

    test "update_period/2 with invalid data returns error changeset" do
      period = period_fixture()
      assert {:error, %Ecto.Changeset{}} = Calendars.update_period(period, @invalid_attrs)
      assert period == Calendars.get_period!(period.id)
    end

    test "delete_period/1 deletes the period" do
      period = period_fixture()
      assert {:ok, %Period{}} = Calendars.delete_period(period)
      assert_raise Ecto.NoResultsError, fn -> Calendars.get_period!(period.id) end
    end

    test "change_period/1 returns a period changeset" do
      period = period_fixture()
      assert %Ecto.Changeset{} = Calendars.change_period(period)
    end
  end

  describe "holiday_or_vacation_types" do
    alias MehrSchulferien.Calendars.HolidayOrVacationType

    @valid_attrs %{colloquial: "some colloquial", default_html_class: "some default_html_class", default_is_listed_below_month: true, default_is_public_holiday: true, default_is_school_vacation: true, default_is_valid_for_everybody: true, default_is_valid_for_students: true, name: "some name", slug: "some slug", wikipedia_url: "some wikipedia_url"}
    @update_attrs %{colloquial: "some updated colloquial", default_html_class: "some updated default_html_class", default_is_listed_below_month: false, default_is_public_holiday: false, default_is_school_vacation: false, default_is_valid_for_everybody: false, default_is_valid_for_students: false, name: "some updated name", slug: "some updated slug", wikipedia_url: "some updated wikipedia_url"}
    @invalid_attrs %{colloquial: nil, default_html_class: nil, default_is_listed_below_month: nil, default_is_public_holiday: nil, default_is_school_vacation: nil, default_is_valid_for_everybody: nil, default_is_valid_for_students: nil, name: nil, slug: nil, wikipedia_url: nil}

    def holiday_or_vacation_type_fixture(attrs \\ %{}) do
      {:ok, holiday_or_vacation_type} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Calendars.create_holiday_or_vacation_type()

      holiday_or_vacation_type
    end

    test "list_holiday_or_vacation_types/0 returns all holiday_or_vacation_types" do
      holiday_or_vacation_type = holiday_or_vacation_type_fixture()
      assert Calendars.list_holiday_or_vacation_types() == [holiday_or_vacation_type]
    end

    test "get_holiday_or_vacation_type!/1 returns the holiday_or_vacation_type with given id" do
      holiday_or_vacation_type = holiday_or_vacation_type_fixture()
      assert Calendars.get_holiday_or_vacation_type!(holiday_or_vacation_type.id) == holiday_or_vacation_type
    end

    test "create_holiday_or_vacation_type/1 with valid data creates a holiday_or_vacation_type" do
      assert {:ok, %HolidayOrVacationType{} = holiday_or_vacation_type} = Calendars.create_holiday_or_vacation_type(@valid_attrs)
      assert holiday_or_vacation_type.colloquial == "some colloquial"
      assert holiday_or_vacation_type.default_html_class == "some default_html_class"
      assert holiday_or_vacation_type.default_is_listed_below_month == true
      assert holiday_or_vacation_type.default_is_public_holiday == true
      assert holiday_or_vacation_type.default_is_school_vacation == true
      assert holiday_or_vacation_type.default_is_valid_for_everybody == true
      assert holiday_or_vacation_type.default_is_valid_for_students == true
      assert holiday_or_vacation_type.name == "some name"
      assert holiday_or_vacation_type.slug == "some slug"
      assert holiday_or_vacation_type.wikipedia_url == "some wikipedia_url"
    end

    test "create_holiday_or_vacation_type/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Calendars.create_holiday_or_vacation_type(@invalid_attrs)
    end

    test "update_holiday_or_vacation_type/2 with valid data updates the holiday_or_vacation_type" do
      holiday_or_vacation_type = holiday_or_vacation_type_fixture()
      assert {:ok, %HolidayOrVacationType{} = holiday_or_vacation_type} = Calendars.update_holiday_or_vacation_type(holiday_or_vacation_type, @update_attrs)
      assert holiday_or_vacation_type.colloquial == "some updated colloquial"
      assert holiday_or_vacation_type.default_html_class == "some updated default_html_class"
      assert holiday_or_vacation_type.default_is_listed_below_month == false
      assert holiday_or_vacation_type.default_is_public_holiday == false
      assert holiday_or_vacation_type.default_is_school_vacation == false
      assert holiday_or_vacation_type.default_is_valid_for_everybody == false
      assert holiday_or_vacation_type.default_is_valid_for_students == false
      assert holiday_or_vacation_type.name == "some updated name"
      assert holiday_or_vacation_type.slug == "some updated slug"
      assert holiday_or_vacation_type.wikipedia_url == "some updated wikipedia_url"
    end

    test "update_holiday_or_vacation_type/2 with invalid data returns error changeset" do
      holiday_or_vacation_type = holiday_or_vacation_type_fixture()
      assert {:error, %Ecto.Changeset{}} = Calendars.update_holiday_or_vacation_type(holiday_or_vacation_type, @invalid_attrs)
      assert holiday_or_vacation_type == Calendars.get_holiday_or_vacation_type!(holiday_or_vacation_type.id)
    end

    test "delete_holiday_or_vacation_type/1 deletes the holiday_or_vacation_type" do
      holiday_or_vacation_type = holiday_or_vacation_type_fixture()
      assert {:ok, %HolidayOrVacationType{}} = Calendars.delete_holiday_or_vacation_type(holiday_or_vacation_type)
      assert_raise Ecto.NoResultsError, fn -> Calendars.get_holiday_or_vacation_type!(holiday_or_vacation_type.id) end
    end

    test "change_holiday_or_vacation_type/1 returns a holiday_or_vacation_type changeset" do
      holiday_or_vacation_type = holiday_or_vacation_type_fixture()
      assert %Ecto.Changeset{} = Calendars.change_holiday_or_vacation_type(holiday_or_vacation_type)
    end
  end

  describe "periods" do
    alias MehrSchulferien.Calendars.Period

    @valid_attrs %{created_by_email_address: "some created_by_email_address", ends_on: ~D[2010-04-17], html_class: "some html_class", is_listed_below_month: true, is_public_holiday: true, is_school_vacation: true, is_valid_for_everybody: true, is_valid_for_students: true, starts_on: ~D[2010-04-17]}
    @update_attrs %{created_by_email_address: "some updated created_by_email_address", ends_on: ~D[2011-05-18], html_class: "some updated html_class", is_listed_below_month: false, is_public_holiday: false, is_school_vacation: false, is_valid_for_everybody: false, is_valid_for_students: false, starts_on: ~D[2011-05-18]}
    @invalid_attrs %{created_by_email_address: nil, ends_on: nil, html_class: nil, is_listed_below_month: nil, is_public_holiday: nil, is_school_vacation: nil, is_valid_for_everybody: nil, is_valid_for_students: nil, starts_on: nil}

    def period_fixture(attrs \\ %{}) do
      {:ok, period} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Calendars.create_period()

      period
    end

    test "list_periods/0 returns all periods" do
      period = period_fixture()
      assert Calendars.list_periods() == [period]
    end

    test "get_period!/1 returns the period with given id" do
      period = period_fixture()
      assert Calendars.get_period!(period.id) == period
    end

    test "create_period/1 with valid data creates a period" do
      assert {:ok, %Period{} = period} = Calendars.create_period(@valid_attrs)
      assert period.created_by_email_address == "some created_by_email_address"
      assert period.ends_on == ~D[2010-04-17]
      assert period.html_class == "some html_class"
      assert period.is_listed_below_month == true
      assert period.is_public_holiday == true
      assert period.is_school_vacation == true
      assert period.is_valid_for_everybody == true
      assert period.is_valid_for_students == true
      assert period.starts_on == ~D[2010-04-17]
    end

    test "create_period/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Calendars.create_period(@invalid_attrs)
    end

    test "update_period/2 with valid data updates the period" do
      period = period_fixture()
      assert {:ok, %Period{} = period} = Calendars.update_period(period, @update_attrs)
      assert period.created_by_email_address == "some updated created_by_email_address"
      assert period.ends_on == ~D[2011-05-18]
      assert period.html_class == "some updated html_class"
      assert period.is_listed_below_month == false
      assert period.is_public_holiday == false
      assert period.is_school_vacation == false
      assert period.is_valid_for_everybody == false
      assert period.is_valid_for_students == false
      assert period.starts_on == ~D[2011-05-18]
    end

    test "update_period/2 with invalid data returns error changeset" do
      period = period_fixture()
      assert {:error, %Ecto.Changeset{}} = Calendars.update_period(period, @invalid_attrs)
      assert period == Calendars.get_period!(period.id)
    end

    test "delete_period/1 deletes the period" do
      period = period_fixture()
      assert {:ok, %Period{}} = Calendars.delete_period(period)
      assert_raise Ecto.NoResultsError, fn -> Calendars.get_period!(period.id) end
    end

    test "change_period/1 returns a period changeset" do
      period = period_fixture()
      assert %Ecto.Changeset{} = Calendars.change_period(period)
    end
  end
end
