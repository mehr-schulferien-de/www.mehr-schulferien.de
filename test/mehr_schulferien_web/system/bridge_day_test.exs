defmodule MehrSchulferienWeb.BridgeDaySystemTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest

  import MehrSchulferien.Factory

  @current_year Date.utc_today().year
  @future_year @current_year + 1
  @past_year @current_year - 100

  setup %{conn: conn} do
    {:ok, %{conn: conn}}
  end

  describe "bridge days for federal state" do
    setup [:add_federal_state, :add_periods]

    test "view bridge days for a federal state with data", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn =
        get(
          conn,
          Routes.bridge_day_path(
            conn,
            :show_within_federal_state,
            country.slug,
            federal_state.slug,
            @future_year
          )
        )

      assert html_response(conn, 200) =~ "Brückentage #{@future_year} in"
      assert html_response(conn, 200) =~ "Tipps"
    end

    test "view bridge days for a federal state without data", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn =
        get(
          conn,
          Routes.bridge_day_path(
            conn,
            :show_within_federal_state,
            country.slug,
            federal_state.slug,
            @past_year
          )
        )

      assert html_response(conn, 404)
    end

    test "view bridge days for an invalid year", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn = get(conn, "/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/foobar")

      # We expect a 404 directly since the route should not exist
      assert conn.status == 404
    end
  end

  defp add_federal_state(_) do
    country = insert(:country, %{slug: "d"})

    federal_state =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "brandenburg",
        name: "Brandenburg"
      })

    {:ok, %{country: country, federal_state: federal_state}}
  end

  defp add_periods(%{federal_state: federal_state}) do
    _public_periods = add_public_periods(%{location: federal_state})
    {:ok, %{federal_state: federal_state}}
  end
end
