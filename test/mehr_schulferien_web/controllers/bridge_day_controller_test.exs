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
      # Use the old route format that goes through the redirects pipeline
      conn = get(conn, "/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}")

      # We expect a 302 temporary redirect
      assert conn.status == 302

      # The redirect URL should contain the correct base path
      redirect_path = redirected_to(conn, 302)

      assert redirect_path =~
               "/land/#{country.slug}/bundesland/#{federal_state.slug}/brueckentage"
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
        insert(:holiday_or_vacation_type, %{
          name: "Test Holiday",
          country_location_id: country.id,
          slug: "test-holiday-#{System.unique_integer([:positive])}"
        })

      weekend_type =
        insert(:holiday_or_vacation_type, %{
          name: "Wochenende",
          country_location_id: country.id,
          slug: "wochenende-#{System.unique_integer([:positive])}"
        })

      # Create a Thursday holiday (May 1st)
      MehrSchulferien.Periods.create_period(%{
        starts_on: ~D[2025-05-01],
        ends_on: ~D[2025-05-01],
        holiday_or_vacation_type_id: holiday_type.id,
        location_id: federal_state.id,
        created_by_email_address: "test@example.com",
        display_priority: 1,
        is_public_holiday: true
      })

      # Create a Sunday holiday (May 4th)
      MehrSchulferien.Periods.create_period(%{
        starts_on: ~D[2025-05-04],
        ends_on: ~D[2025-05-04],
        holiday_or_vacation_type_id: holiday_type.id,
        location_id: federal_state.id,
        created_by_email_address: "test@example.com",
        display_priority: 2,
        is_public_holiday: true
      })

      # Add weekend days (Saturday and Sunday)
      MehrSchulferien.Periods.create_period(%{
        starts_on: ~D[2025-05-03],
        ends_on: ~D[2025-05-04],
        holiday_or_vacation_type_id: weekend_type.id,
        location_id: federal_state.id,
        created_by_email_address: "test@example.com",
        display_priority: 3,
        is_public_holiday: false
      })

      conn = get(conn, "/brueckentage/d-test/bundesland/brandenburg-test/2025")

      # We expect a redirect first
      assert conn.status == 302

      # Follow the redirect
      redirected_path = redirected_to(conn, 302)
      conn = get(recycle(conn), redirected_path)

      # Now we should get a 200
      assert html_response(conn, 200)
      assert conn.resp_body =~ "Brückentage 2025 in Brandenburg Test"
      assert conn.resp_body =~ "Super-Brückentag"
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
