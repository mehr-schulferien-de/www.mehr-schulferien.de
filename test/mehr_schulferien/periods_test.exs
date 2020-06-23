defmodule MehrSchulferien.PeriodsTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.{Periods, Periods.ICal, Periods.Period}
  alias MehrSchulferien.Locations

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
      assert [period_1] = Periods.list_periods()
      assert period.id == period_1.id
    end

    test "get_period!/1 returns the period with given id" do
      period = insert(:period)
      assert period_1 = Periods.get_period!(period.id)
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

      assert {:ok, %Period{} = period} = Periods.create_period(valid_attrs)

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

      assert {:ok, %Period{} = period} = Periods.create_period(valid_attrs)
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

      assert {:error, %Ecto.Changeset{} = changeset} = Periods.create_period(invalid_attrs)

      assert %{starts_on: ["starts_on should be less than or equal to ends_on"]} =
               errors_on(changeset)

      invalid_attrs = Map.put(invalid_attrs, "ends_on", nil)
      assert {:error, %Ecto.Changeset{} = changeset} = Periods.create_period(invalid_attrs)
      assert %{ends_on: ["can't be blank"]} = errors_on(changeset)
    end

    test "update_period/2 with valid data updates the period" do
      period = insert(:period)
      assert {:ok, %Period{} = period} = Periods.update_period(period, @update_attrs)
      assert period.html_class == "white"
      assert period.is_public_holiday == true
    end

    test "update_period/2 with invalid data returns error changeset" do
      period = insert(:period)
      assert {:error, %Ecto.Changeset{}} = Periods.update_period(period, @invalid_attrs)
    end

    test "delete_period/1 deletes the period" do
      period = insert(:period)
      assert {:ok, %Period{}} = Periods.delete_period(period)
      assert_raise Ecto.NoResultsError, fn -> Periods.get_period!(period.id) end
    end

    test "change_period/1 returns a period changeset" do
      period = insert(:period)
      assert %Ecto.Changeset{} = Periods.change_period(period)
    end

    test "find_periods_by_month/2 returns periods if the month has a holiday" do
      _period_1 = insert(:period, %{starts_on: ~D[2020-02-04], ends_on: ~D[2020-02-07]})
      _period_2 = insert(:period, %{starts_on: ~D[2020-02-24], ends_on: ~D[2020-02-27]})
      period_3 = insert(:period, %{starts_on: ~D[2020-04-04], ends_on: ~D[2020-06-07]})
      periods = Periods.list_periods()
      assert Periods.find_periods_by_month(~D[2020-01-01], periods) == []
      assert length(Periods.find_periods_by_month(~D[2020-02-01], periods)) == 2
      assert [%Period{id: id}] = Periods.find_periods_by_month(~D[2020-04-01], periods)
      assert id == period_3.id
      assert [%Period{id: ^id}] = Periods.find_periods_by_month(~D[2020-05-01], periods)
      assert [%Period{id: ^id}] = Periods.find_periods_by_month(~D[2020-06-01], periods)
      assert Periods.find_periods_by_month(~D[2020-08-01], periods) == []
    end
  end

  describe "periods for certain time frame" do
    setup [:add_federal_state, :add_periods]

    test "list_school_periods/4 returns all periods within a time frame", %{
      federal_state: federal_state,
      school_periods: school_periods,
      other_period: other_period
    } do
      location_ids = Locations.recursive_location_ids(federal_state)
      period_ids = Enum.map(school_periods, & &1.id)

      short_time_periods =
        Periods.list_school_periods(location_ids, ~D[2021-02-01], ~D[2022-01-31])

      assert length(short_time_periods) == 5

      # results include a holiday that has already started, but not ended yet
      short_time_periods =
        Periods.list_school_periods(location_ids, ~D[2021-04-11], ~D[2021-12-31])

      assert length(short_time_periods) == 4
      assert Enum.all?(short_time_periods, &(&1.id in period_ids))

      long_time_periods =
        Periods.list_school_periods(location_ids, ~D[2020-01-01], ~D[2022-12-31])

      assert Enum.all?(long_time_periods, &(&1.id in period_ids))
      assert other_period not in short_time_periods
      assert other_period not in long_time_periods
    end

    test "group_periods_single_year/2 groups periods with the same name together", %{
      federal_state: federal_state
    } do
      location_ids = Locations.recursive_location_ids(federal_state)
      today = ~D[2021-02-26]
      first_day = ~D[2021-01-01]
      last_day = ~D[2022-12-31]
      school_periods = Periods.list_school_periods(location_ids, first_day, last_day)
      assert length(school_periods) == 9
      grouped_periods = Periods.group_periods_single_year(school_periods, today)
      assert length(grouped_periods) == 5
      today = ~D[2021-03-02]
      school_periods = Periods.list_school_periods(location_ids, first_day, last_day)
      assert length(school_periods) == 9
      grouped_periods = Periods.group_periods_single_year(school_periods, today)
      assert length(grouped_periods) == 4
    end
  end

  describe "filter periods" do
    setup [:add_federal_state, :add_periods]

    test "next_periods/3 returns a certain number of next periods", %{
      school_periods: school_periods
    } do
      today = ~D[2020-04-02]
      assert [period_1, period_2, period_3] = Periods.next_periods(school_periods, today, 3)
      assert period_1.starts_on == ~D[2020-04-06]
      assert period_2.starts_on == ~D[2020-10-31]
      assert period_3.starts_on == ~D[2020-12-23]
      today = ~D[2020-05-16]
      assert [period_4, period_5] = Periods.next_periods(school_periods, today, 2)
      assert period_4 == period_2
      assert period_5 == period_3
    end

    test "find_most_recent_period/2 returns the most recently ended period", %{
      school_periods: school_periods
    } do
      today = ~D[2020-05-02]
      period = Periods.find_most_recent_period(school_periods, today)
      assert period.starts_on == ~D[2020-04-06]
      today = ~D[2021-03-16]
      period = Periods.find_most_recent_period(school_periods, today)
      assert period.starts_on == ~D[2021-02-24]
    end
  end

  describe "icalendar" do
    test "period_to_event/1 converts period to an ICalendar event" do
      federal_state = insert(:federal_state)
      vacation_type = insert(:holiday_or_vacation_type)

      period =
        create_period(%{
          ends_on: ~D[2020-07-10],
          location_id: federal_state.id,
          starts_on: ~D[2020-07-07],
          vacation_type_id: vacation_type.id
        })

      assert %ICalendar.Event{
               dtend: dtend,
               dtstart: dtstart,
               location: location,
               summary: summary
             } = ICal.period_to_event(period, federal_state)

      assert dtend == {{2020, 7, 10}, {23, 59, 59}}
      assert dtstart == {{2020, 7, 7}, {0, 0, 0}}
      assert location == federal_state.name
      assert summary == vacation_type.colloquial
    end
  end

  defp add_federal_state(_) do
    federal_state = insert(:federal_state)
    {:ok, %{federal_state: federal_state}}
  end

  defp add_periods(%{federal_state: federal_state}) do
    school_periods = add_school_periods(%{location: federal_state})

    other_period =
      insert(:period, %{
        is_school_vacation: true,
        is_valid_for_students: true,
        starts_on: ~D[2020-10-31],
        ends_on: ~D[2020-10-31]
      })

    {:ok,
     %{federal_state: federal_state, school_periods: school_periods, other_period: other_period}}
  end

  defp create_period(%{
         ends_on: ends_on,
         location_id: location_id,
         starts_on: starts_on,
         vacation_type_id: vacation_type_id
       }) do
    {:ok, period} =
      Periods.create_period(%{
        created_by_email_address: "froderick@example.com",
        location_id: location_id,
        holiday_or_vacation_type_id: vacation_type_id,
        starts_on: starts_on,
        ends_on: ends_on
      })

    Periods.get_period!(period.id)
  end
end
