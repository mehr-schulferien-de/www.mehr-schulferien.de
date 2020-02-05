defmodule MehrSchulferienWeb.FederalStateControllerTest do
  use MehrSchulferienWeb.ConnCase

  describe "read federal state display data" do
    setup [:add_federal_state, :add_periods]

    test "shows a federal state display", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, Routes.federal_state_path(conn, :show, federal_state))
      assert html_response(conn, 200) =~ federal_state.name
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
