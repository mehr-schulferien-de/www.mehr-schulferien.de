defmodule MehrSchulferienWeb.SitemapControllerTest do
  use MehrSchulferienWeb.ConnCase

  setup %{conn: conn} do
    {:ok, %{conn: conn}}
  end

  describe "GET /sitemap.xml" do
    setup [:add_federal_state_with_bridge_days]

    test "access the sitemap in format xml", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, "/sitemap.xml")
      assert response_content_type(conn, :xml)
      assert response(conn, 200) =~ ~r/<loc>.*\/bundesland\/#{federal_state.slug}.*<\/loc>/
    end
  end

  defp add_federal_state_with_bridge_days(_) do
    country = insert(:country, %{slug: "d"})
    federal_state = insert(:federal_state, %{parent_location_id: country.id, slug: "berlin"})

    # Add a holiday type for bridge days
    holiday_type =
      insert(:holiday_or_vacation_type, %{
        name: "Test Holiday",
        country_location_id: country.id
      })

    # Get the current year
    current_year = Date.utc_today().year

    # Create a public holiday in the current year to create a bridge day
    create_period(%{
      is_public_holiday: true,
      is_valid_for_everybody: true,
      location_id: federal_state.id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(current_year, 5, 1),
      ends_on: Date.new!(current_year, 5, 1),
      display_priority: 1,
      created_by_email_address: "test@example.com"
    })

    # Create a day off before the public holiday to form a bridge day
    create_period(%{
      is_public_holiday: false,
      is_valid_for_everybody: true,
      location_id: federal_state.id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(current_year, 4, 30),
      ends_on: Date.new!(current_year, 4, 30),
      display_priority: 1,
      created_by_email_address: "test@example.com"
    })

    # Create a public holiday for next year too
    next_year = current_year + 1

    create_period(%{
      is_public_holiday: true,
      is_valid_for_everybody: true,
      location_id: federal_state.id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(next_year, 5, 1),
      ends_on: Date.new!(next_year, 5, 1),
      display_priority: 1,
      created_by_email_address: "test@example.com"
    })

    # Create a day off before the public holiday to form a bridge day for next year
    create_period(%{
      is_public_holiday: false,
      is_valid_for_everybody: true,
      location_id: federal_state.id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(next_year, 4, 30),
      ends_on: Date.new!(next_year, 4, 30),
      display_priority: 1,
      created_by_email_address: "test@example.com"
    })

    {:ok, %{country: country, federal_state: federal_state}}
  end

  defp create_period(attrs) do
    {:ok, period} = MehrSchulferien.Periods.create_period(attrs)
    period
  end
end
