defmodule MehrSchulferien.TimetablesTest do
  use MehrSchulferien.DataCase

  alias MehrSchulferien.Timetables

  describe "years" do
    alias MehrSchulferien.Timetables.Year

    @valid_attrs %{slug: "some slug", value: 42}
    @update_attrs %{slug: "some updated slug", value: 43}
    @invalid_attrs %{slug: nil, value: nil}

    def year_fixture(attrs \\ %{}) do
      {:ok, year} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Timetables.create_year()

      year
    end

    test "list_years/0 returns all years" do
      year = year_fixture()
      assert Timetables.list_years() == [year]
    end

    test "get_year!/1 returns the year with given id" do
      year = year_fixture()
      assert Timetables.get_year!(year.id) == year
    end

    test "create_year/1 with valid data creates a year" do
      assert {:ok, %Year{} = year} = Timetables.create_year(@valid_attrs)
      assert year.slug == "some slug"
      assert year.value == 42
    end

    test "create_year/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Timetables.create_year(@invalid_attrs)
    end

    test "update_year/2 with valid data updates the year" do
      year = year_fixture()
      assert {:ok, year} = Timetables.update_year(year, @update_attrs)
      assert %Year{} = year
      assert year.slug == "some updated slug"
      assert year.value == 43
    end

    test "update_year/2 with invalid data returns error changeset" do
      year = year_fixture()
      assert {:error, %Ecto.Changeset{}} = Timetables.update_year(year, @invalid_attrs)
      assert year == Timetables.get_year!(year.id)
    end

    test "delete_year/1 deletes the year" do
      year = year_fixture()
      assert {:ok, %Year{}} = Timetables.delete_year(year)
      assert_raise Ecto.NoResultsError, fn -> Timetables.get_year!(year.id) end
    end

    test "change_year/1 returns a year changeset" do
      year = year_fixture()
      assert %Ecto.Changeset{} = Timetables.change_year(year)
    end
  end

  describe "months" do
    alias MehrSchulferien.Timetables.Month

    @valid_attrs %{slug: "some slug", value: 42}
    @update_attrs %{slug: "some updated slug", value: 43}
    @invalid_attrs %{slug: nil, value: nil}

    def month_fixture(attrs \\ %{}) do
      {:ok, month} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Timetables.create_month()

      month
    end

    test "list_months/0 returns all months" do
      month = month_fixture()
      assert Timetables.list_months() == [month]
    end

    test "get_month!/1 returns the month with given id" do
      month = month_fixture()
      assert Timetables.get_month!(month.id) == month
    end

    test "create_month/1 with valid data creates a month" do
      assert {:ok, %Month{} = month} = Timetables.create_month(@valid_attrs)
      assert month.slug == "some slug"
      assert month.value == 42
    end

    test "create_month/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Timetables.create_month(@invalid_attrs)
    end

    test "update_month/2 with valid data updates the month" do
      month = month_fixture()
      assert {:ok, month} = Timetables.update_month(month, @update_attrs)
      assert %Month{} = month
      assert month.slug == "some updated slug"
      assert month.value == 43
    end

    test "update_month/2 with invalid data returns error changeset" do
      month = month_fixture()
      assert {:error, %Ecto.Changeset{}} = Timetables.update_month(month, @invalid_attrs)
      assert month == Timetables.get_month!(month.id)
    end

    test "delete_month/1 deletes the month" do
      month = month_fixture()
      assert {:ok, %Month{}} = Timetables.delete_month(month)
      assert_raise Ecto.NoResultsError, fn -> Timetables.get_month!(month.id) end
    end

    test "change_month/1 returns a month changeset" do
      month = month_fixture()
      assert %Ecto.Changeset{} = Timetables.change_month(month)
    end
  end

  describe "days" do
    alias MehrSchulferien.Timetables.Day

    @valid_attrs %{calendar_week: 42, day_of_month: 42, day_of_year: 42, slug: "some slug", value: ~D[2010-04-17], weekday: 42, weekday_de: "some weekday_de"}
    @update_attrs %{calendar_week: 43, day_of_month: 43, day_of_year: 43, slug: "some updated slug", value: ~D[2011-05-18], weekday: 43, weekday_de: "some updated weekday_de"}
    @invalid_attrs %{calendar_week: nil, day_of_month: nil, day_of_year: nil, slug: nil, value: nil, weekday: nil, weekday_de: nil}

    def day_fixture(attrs \\ %{}) do
      {:ok, day} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Timetables.create_day()

      day
    end

    test "list_days/0 returns all days" do
      day = day_fixture()
      assert Timetables.list_days() == [day]
    end

    test "get_day!/1 returns the day with given id" do
      day = day_fixture()
      assert Timetables.get_day!(day.id) == day
    end

    test "create_day/1 with valid data creates a day" do
      assert {:ok, %Day{} = day} = Timetables.create_day(@valid_attrs)
      assert day.calendar_week == 42
      assert day.day_of_month == 42
      assert day.day_of_year == 42
      assert day.slug == "some slug"
      assert day.value == ~D[2010-04-17]
      assert day.weekday == 42
      assert day.weekday_de == "some weekday_de"
    end

    test "create_day/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Timetables.create_day(@invalid_attrs)
    end

    test "update_day/2 with valid data updates the day" do
      day = day_fixture()
      assert {:ok, day} = Timetables.update_day(day, @update_attrs)
      assert %Day{} = day
      assert day.calendar_week == 43
      assert day.day_of_month == 43
      assert day.day_of_year == 43
      assert day.slug == "some updated slug"
      assert day.value == ~D[2011-05-18]
      assert day.weekday == 43
      assert day.weekday_de == "some updated weekday_de"
    end

    test "update_day/2 with invalid data returns error changeset" do
      day = day_fixture()
      assert {:error, %Ecto.Changeset{}} = Timetables.update_day(day, @invalid_attrs)
      assert day == Timetables.get_day!(day.id)
    end

    test "delete_day/1 deletes the day" do
      day = day_fixture()
      assert {:ok, %Day{}} = Timetables.delete_day(day)
      assert_raise Ecto.NoResultsError, fn -> Timetables.get_day!(day.id) end
    end

    test "change_day/1 returns a day changeset" do
      day = day_fixture()
      assert %Ecto.Changeset{} = Timetables.change_day(day)
    end
  end

  describe "categories" do
    alias MehrSchulferien.Timetables.Category

    @valid_attrs %{for_anybody: true, for_students: true, name: "some name", needs_exeat: true, slug: "some slug"}
    @update_attrs %{for_anybody: false, for_students: false, name: "some updated name", needs_exeat: false, slug: "some updated slug"}
    @invalid_attrs %{for_anybody: nil, for_students: nil, name: nil, needs_exeat: nil, slug: nil}

    def category_fixture(attrs \\ %{}) do
      {:ok, category} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Timetables.create_category()

      category
    end

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert Timetables.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert Timetables.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      assert {:ok, %Category{} = category} = Timetables.create_category(@valid_attrs)
      assert category.for_anybody == true
      assert category.for_students == true
      assert category.name == "some name"
      assert category.needs_exeat == true
      assert category.slug == "some slug"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Timetables.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      assert {:ok, category} = Timetables.update_category(category, @update_attrs)
      assert %Category{} = category
      assert category.for_anybody == false
      assert category.for_students == false
      assert category.name == "some updated name"
      assert category.needs_exeat == false
      assert category.slug == "some updated slug"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Timetables.update_category(category, @invalid_attrs)
      assert category == Timetables.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Timetables.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Timetables.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Timetables.change_category(category)
    end
  end

  describe "periods" do
    alias MehrSchulferien.Timetables.Period

    @valid_attrs %{ends_on: ~D[2010-04-17], for_anybody: true, for_students: true, is_a_religion: true, name: "some name", needs_exeat: true, slug: "some slug", source: "some source", starts_on: ~D[2010-04-17]}
    @update_attrs %{ends_on: ~D[2011-05-18], for_anybody: false, for_students: false, is_a_religion: false, name: "some updated name", needs_exeat: false, slug: "some updated slug", source: "some updated source", starts_on: ~D[2011-05-18]}
    @invalid_attrs %{ends_on: nil, for_anybody: nil, for_students: nil, is_a_religion: nil, name: nil, needs_exeat: nil, slug: nil, source: nil, starts_on: nil}

    def period_fixture(attrs \\ %{}) do
      {:ok, period} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Timetables.create_period()

      period
    end

    test "list_periods/0 returns all periods" do
      period = period_fixture()
      assert Timetables.list_periods() == [period]
    end

    test "get_period!/1 returns the period with given id" do
      period = period_fixture()
      assert Timetables.get_period!(period.id) == period
    end

    test "create_period/1 with valid data creates a period" do
      assert {:ok, %Period{} = period} = Timetables.create_period(@valid_attrs)
      assert period.ends_on == ~D[2010-04-17]
      assert period.for_anybody == true
      assert period.for_students == true
      assert period.is_a_religion == true
      assert period.name == "some name"
      assert period.needs_exeat == true
      assert period.slug == "some slug"
      assert period.source == "some source"
      assert period.starts_on == ~D[2010-04-17]
    end

    test "create_period/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Timetables.create_period(@invalid_attrs)
    end

    test "update_period/2 with valid data updates the period" do
      period = period_fixture()
      assert {:ok, period} = Timetables.update_period(period, @update_attrs)
      assert %Period{} = period
      assert period.ends_on == ~D[2011-05-18]
      assert period.for_anybody == false
      assert period.for_students == false
      assert period.is_a_religion == false
      assert period.name == "some updated name"
      assert period.needs_exeat == false
      assert period.slug == "some updated slug"
      assert period.source == "some updated source"
      assert period.starts_on == ~D[2011-05-18]
    end

    test "update_period/2 with invalid data returns error changeset" do
      period = period_fixture()
      assert {:error, %Ecto.Changeset{}} = Timetables.update_period(period, @invalid_attrs)
      assert period == Timetables.get_period!(period.id)
    end

    test "delete_period/1 deletes the period" do
      period = period_fixture()
      assert {:ok, %Period{}} = Timetables.delete_period(period)
      assert_raise Ecto.NoResultsError, fn -> Timetables.get_period!(period.id) end
    end

    test "change_period/1 returns a period changeset" do
      period = period_fixture()
      assert %Ecto.Changeset{} = Timetables.change_period(period)
    end
  end
end
