defmodule MehrSchulferienWeb.BridgeDayNavigationSystemTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest
  import MehrSchulferien.Factory

  @current_year Date.utc_today().year
  @future_year @current_year + 1

  setup %{conn: conn} do
    {:ok, %{conn: conn}}
  end

  describe "bridge day pagination links" do
    setup [:add_federal_state, :add_periods_for_specific_years]

    test "only shows navigation links to years with bridge days", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      # Test viewing current year (which has bridge days)
      conn =
        get(
          conn,
          Routes.bridge_day_path(
            conn,
            :show_within_federal_state,
            country.slug,
            federal_state.slug,
            @current_year
          )
        )

      # Page loads successfully
      assert html_response(conn, 200) =~ "Brückentage #{@current_year} in"

      # Check if future year (which has bridge days) is shown in navigation
      assert html_response(conn, 200) =~
               ~s(href="/land/#{country.slug}/bundesland/#{federal_state.slug}/brueckentage/#{@future_year}")

      # Past year (which doesn't have bridge days) should not be linked
      past_year = @current_year - 1

      refute html_response(conn, 200) =~
               ~s(href="/land/#{country.slug}/bundesland/#{federal_state.slug}/brueckentage/#{past_year}")

      # The left arrow should be disabled (not a link) since past_year has no bridge days
      assert html_response(conn, 200) =~
               ~s(class="px-4 py-2 text-sm font-medium bg-gray-50 text-gray-400 border border-gray-200 rounded-l-lg flex items-center cursor-not-allowed")
    end

    test "correctly handles years that don't have neighboring years with bridge days", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      # Test viewing only future year (where next year doesn't have bridge days)
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

      # Page loads successfully
      assert html_response(conn, 200) =~ "Brückentage #{@future_year} in"

      # Previous year (which has bridge days) should be linked
      assert html_response(conn, 200) =~
               ~s(href="/land/#{country.slug}/bundesland/#{federal_state.slug}/brueckentage/#{@current_year}")

      # Future+1 year doesn't have bridge days, so right arrow should be disabled
      assert html_response(conn, 200) =~
               ~s(class="px-4 py-2 text-sm font-medium bg-gray-50 text-gray-400 border border-gray-200 rounded-r-lg flex items-center cursor-not-allowed")
    end
  end

  defp add_federal_state(_) do
    country = insert(:country, %{slug: "d"})

    federal_state =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "niedersachsen",
        name: "Niedersachsen"
      })

    {:ok, %{country: country, federal_state: federal_state}}
  end

  defp add_periods_for_specific_years(%{federal_state: federal_state}) do
    # Only add bridge days for current year and future year
    # Deliberately NOT adding bridge days for current_year - 1

    # Add bridge days for current year
    create_bridge_day_periods(federal_state.id, @current_year)

    # Add bridge days for future year
    create_bridge_day_periods(federal_state.id, @future_year)

    # Do NOT add bridge days for future_year + 1

    {:ok, %{federal_state: federal_state}}
  end

  defp create_bridge_day_periods(location_id, year) do
    holiday_type =
      insert(:holiday_or_vacation_type, %{
        name: "Test Holiday",
        slug: "test-holiday-#{year}-#{System.unique_integer([:positive])}"
      })

    weekend_type =
      insert(:holiday_or_vacation_type, %{
        name: "Wochenende",
        slug: "wochenende-#{year}-#{System.unique_integer([:positive])}"
      })

    # Create a bridge day scenario that meets minimum gain requirements
    # Thursday holiday (May 1st)
    create_period(%{
      is_public_holiday: true,
      is_valid_for_everybody: true,
      location_id: location_id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(year, 5, 1),
      ends_on: Date.new!(year, 5, 1),
      display_priority: 1,
      created_by_email_address: "test@example.com"
    })

    # Weekend days (Saturday and Sunday)
    create_period(%{
      is_public_holiday: false,
      is_valid_for_everybody: true,
      location_id: location_id,
      holiday_or_vacation_type_id: weekend_type.id,
      starts_on: Date.new!(year, 5, 3),
      ends_on: Date.new!(year, 5, 4),
      display_priority: 3,
      created_by_email_address: "test@example.com"
    })
  end

  defp create_period(attrs) do
    {:ok, period} = MehrSchulferien.Periods.create_period(attrs)
    period
  end
end
