defmodule MehrSchulferienWeb.BridgeDayControllerTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest

  alias MehrSchulferien.Calendars.DateHelpers

  setup %{conn: conn} do
    {:ok, %{conn: conn}}
  end

  describe "read federal state data" do
    setup [:add_federal_state, :add_periods]

    test "returns 200 for valid bridge day URL", %{
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

      assert html_response(conn, 200)
      assert conn.resp_body =~ "Brückentage #{current_year} in #{federal_state.name}"
    end

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

    test "returns 200 and FAQ for Brandenburg 2025", %{conn: conn} do
      country = insert(:country, %{slug: "d-test", name: "Deutschland Test"})

      federal_state =
        insert(:federal_state, %{
          slug: "brandenburg-test",
          name: "Brandenburg Test",
          parent_location_id: country.id
        })

      holiday_type =
        insert(:holiday_or_vacation_type, %{name: "Test Holiday", country_location_id: country.id})

      # Add two periods to create a bridge day
      MehrSchulferien.Periods.create_period(%{
        starts_on: ~D[2025-05-01],
        ends_on: ~D[2025-05-01],
        holiday_or_vacation_type_id: holiday_type.id,
        location_id: federal_state.id,
        created_by_email_address: "test@example.com",
        display_priority: 1,
        is_public_holiday: true
      })

      MehrSchulferien.Periods.create_period(%{
        starts_on: ~D[2025-05-03],
        ends_on: ~D[2025-05-03],
        holiday_or_vacation_type_id: holiday_type.id,
        location_id: federal_state.id,
        created_by_email_address: "test@example.com",
        display_priority: 2,
        is_public_holiday: true
      })

      conn = get(conn, "/brueckentage/d-test/bundesland/brandenburg-test/2025")
      assert html_response(conn, 200)
      assert conn.resp_body =~ "Brückentage 2025 in Brandenburg Test"
      assert conn.resp_body =~ "Brückentag-FAQ"
      assert conn.resp_body =~ "Der beste Brückentag ist"
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
