defmodule MehrSchulferienWeb.CityRedirectSystemTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest

  import MehrSchulferien.Factory

  @current_year Date.utc_today().year

  setup %{conn: conn} do
    {:ok, %{conn: conn}}
  end

  describe "city redirect" do
    setup [:add_city]

    test "redirects from city base URL to current year URL", %{
      conn: conn,
      country: country,
      city: city
    } do
      conn = get(conn, "/ferien/#{country.slug}/stadt/#{city.slug}")

      # Assert that we get a 302 redirect to the current year URL
      assert redirected_to(conn, 302) ==
               "/ferien/#{country.slug}/stadt/#{city.slug}/#{@current_year}"
    end
  end

  defp add_city(_) do
    country = insert(:country, %{slug: "d"})

    federal_state =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "rheinland-pfalz",
        name: "Rheinland-Pfalz"
      })

    county =
      insert(:county, %{
        parent_location_id: federal_state.id,
        slug: "landkreis-neuwied",
        name: "Landkreis Neuwied"
      })

    city =
      insert(:city, %{
        parent_location_id: county.id,
        slug: "neuwied",
        name: "Neuwied"
      })

    # Create school vacation periods
    holiday_type = insert(:holiday_or_vacation_type, %{name: "Sommerferien"})

    create_period(%{
      is_public_holiday: false,
      is_school_vacation: true,
      location_id: federal_state.id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(@current_year, 7, 1),
      ends_on: Date.new!(@current_year, 8, 15),
      display_priority: 1,
      created_by_email_address: "test@example.com"
    })

    # Add public holidays
    add_public_periods(%{location: federal_state})

    {:ok, %{country: country, federal_state: federal_state, county: county, city: city}}
  end

  defp create_period(attrs) do
    {:ok, period} = MehrSchulferien.Periods.create_period(attrs)
    period
  end
end
