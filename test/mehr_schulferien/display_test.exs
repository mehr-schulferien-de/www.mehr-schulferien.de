defmodule MehrSchulferien.DisplayTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.Display
  alias MehrSchulferien.Maps

  describe "federal states" do
    setup [:add_federal_state]

    test "list_federal_states/1 returns all federal states", %{federal_state: federal_state} do
      assert length(Maps.list_locations()) == 2
      assert [federal_state_1] = Display.list_federal_states()
      assert federal_state_1.id == federal_state.id
    end

    test "get_federal_state!/1 gets certain federal state", %{federal_state: federal_state} do
      assert federal_state_1 = Display.get_federal_state!(federal_state.id)
      assert federal_state_1.is_federal_state
    end
  end

  describe "periods for certain time frame" do
    setup [:add_federal_state, :add_periods]

    test "get_periods_by_time/4 returns all periods within a time frame", %{
      federal_state: federal_state,
      periods: periods,
      other_period: other_period
    } do
      location_ids = Maps.recursive_location_ids(federal_state)
      period_ids = Enum.map(periods, & &1.id)

      short_time_periods =
        Display.get_periods_by_time(location_ids, ~D[2020-02-01], ~D[2021-01-31], true)

      assert length(short_time_periods) == 4

      # results include a holiday that has already started, but not ended yet
      short_time_periods =
        Display.get_periods_by_time(location_ids, ~D[2020-04-11], ~D[2020-12-31], true)

      assert length(short_time_periods) == 4
      assert Enum.all?(short_time_periods, &(&1.id in period_ids))

      long_time_periods =
        Display.get_periods_by_time(location_ids, ~D[2019-01-01], ~D[2021-12-31], false)

      assert Enum.all?(long_time_periods, &(&1.id in period_ids))
      assert other_period not in short_time_periods
      assert other_period not in long_time_periods
    end
  end

  defp add_federal_state(_) do
    federal_state = insert(:location)
    {:ok, %{federal_state: federal_state}}
  end

  defp add_periods(%{federal_state: federal_state}) do
    oster = insert(:holiday_or_vacation_type, %{name: "Oster"})
    herbst = insert(:holiday_or_vacation_type, %{name: "Herbst"})
    weihnachts = insert(:holiday_or_vacation_type, %{name: "Weihnachts"})

    data = [
      {oster, ~D[2019-04-06], ~D[2019-04-18]},
      {herbst, ~D[2019-10-31], ~D[2019-10-31]},
      {weihnachts, ~D[2019-12-23], ~D[2020-01-04]},
      {oster, ~D[2020-04-06], ~D[2020-04-18]},
      {herbst, ~D[2020-10-24], ~D[2020-10-27]},
      {herbst, ~D[2020-10-31], ~D[2020-10-31]},
      {weihnachts, ~D[2020-12-23], ~D[2021-01-04]},
      {oster, ~D[2021-04-06], ~D[2021-04-18]},
      {herbst, ~D[2021-10-31], ~D[2021-10-31]},
      {weihnachts, ~D[2021-12-23], ~D[2022-01-04]}
    ]

    periods =
      for {vacation_type, starts_on, ends_on} <- data do
        create_period(%{
          created_by_email_address: "froderick@example.com",
          location_id: federal_state.id,
          holiday_or_vacation_type_id: vacation_type.id,
          starts_on: starts_on,
          ends_on: ends_on
        })
      end

    other_period =
      insert(:period, %{
        is_school_vacation: true,
        is_valid_for_students: true,
        starts_on: ~D[2020-10-31],
        ends_on: ~D[2020-10-31]
      })

    {:ok, %{federal_state: federal_state, periods: periods, other_period: other_period}}
  end

  defp create_period(attrs) do
    {:ok, period} = MehrSchulferien.Calendars.create_period(attrs)
    period
  end
end
