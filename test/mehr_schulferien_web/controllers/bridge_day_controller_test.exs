defmodule MehrSchulferienWeb.BridgeDayControllerTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest

  alias MehrSchulferien.Calendars.DateHelpers

  setup %{conn: conn} do
    {:ok, %{conn: conn}}
  end

  describe "read federal state data" do
    setup [:add_federal_state, :add_periods]

    test "lists available years for bridge days", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn =
        get(
          conn,
          Routes.bridge_day_path(
            conn,
            :index_within_federal_state,
            country.slug,
            federal_state.slug
          )
        )

      assert conn.status in [301, 302]

      assert get_resp_header(conn, "location") |> Enum.at(0) =~
               "/brueckentage/d/bundesland/#{federal_state.slug}"
    end

    test "shows certain year for bridge days", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      today = DateHelpers.today_berlin()
      current_year = today.year

      conn =
        get(
          conn,
          Routes.bridge_day_path(
            conn,
            :show_within_federal_state,
            country.slug,
            federal_state.slug,
            current_year
          )
        )

      assert html_response(conn, 200) =~ "#{current_year}"
    end

    test "returns 404 for invalid year", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      today = DateHelpers.today_berlin()
      invalid_year = today.year + 3

      conn =
        get(
          conn,
          Routes.bridge_day_path(
            conn,
            :show_within_federal_state,
            country.slug,
            federal_state.slug,
            invalid_year
          )
        )

      assert conn.status == 404
    end
  end

  defp add_federal_state(_) do
    country = insert(:country, %{slug: "d"})
    federal_state = insert(:federal_state, %{parent_location_id: country.id, slug: "berlin"})
    {:ok, %{country: country, federal_state: federal_state}}
  end

  defp add_periods(%{federal_state: federal_state}) do
    _public_periods = add_public_periods(%{location: federal_state})
    {:ok, %{federal_state: federal_state}}
  end
end
