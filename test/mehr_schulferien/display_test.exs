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

      assert short_time_periods =
               Display.get_periods_by_time(location_ids, ~D[2020-02-01], ~D[2021-01-31], true)

      assert length(short_time_periods) == 3

      # results include already a holiday that has already started, but not ended yet
      assert short_time_periods =
               Display.get_periods_by_time(location_ids, ~D[2020-04-11], ~D[2020-12-31], true)

      assert length(short_time_periods) == 3

      assert Enum.all?(short_time_periods, &(&1.id in period_ids))

      assert long_time_periods =
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
    dates = [
      {~D[2019-04-06], ~D[2019-04-18]},
      {~D[2019-10-31], ~D[2019-10-31]},
      {~D[2019-12-23], ~D[2020-01-04]},
      {~D[2020-04-06], ~D[2020-04-18]},
      {~D[2020-10-31], ~D[2020-10-31]},
      {~D[2020-12-23], ~D[2021-01-04]},
      {~D[2021-04-06], ~D[2021-04-18]},
      {~D[2021-10-31], ~D[2021-10-31]},
      {~D[2021-12-23], ~D[2022-01-04]}
    ]

    periods =
      for {starts_on, ends_on} <- dates do
        insert(:period, %{
          is_school_vacation: true,
          is_valid_for_students: true,
          location_id: federal_state.id,
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
end
