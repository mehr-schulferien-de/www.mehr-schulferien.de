defmodule MehrSchulferienWeb.SitemapSystemTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest

  import MehrSchulferien.Factory

  @current_year Date.utc_today().year
  @next_year @current_year + 1

  setup %{conn: conn} do
    {:ok, %{conn: conn}}
  end

  describe "sitemap.xml" do
    setup [:add_country_with_data]

    test "sitemap.xml endpoint returns 200 status and correct format", %{
      conn: conn,
      country: _country,
      federal_state: _federal_state,
      city: _city,
      school: _school
    } do
      conn = get(conn, "/sitemap.xml")

      # Check status and content type
      assert conn.status == 200
      assert response_content_type(conn, :xml)

      # Check XML format
      response = response(conn, 200)
      assert response =~ ~s(<?xml version="1.0" encoding="UTF-8"?>)
      assert response =~ ~s(<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">)

      # Check main pages - homepage URL
      assert response =~ ~r{<loc>https?://[^<]+/</loc>}

      # Check developers page
      assert response =~ ~r{<loc>https?://[^<]+/developers</loc>}

      # Check country URL is present
      assert response =~ ~r{<loc>https?://[^<]+/land/d</loc>}

      # We don't check federal state, city and school URLs in this test since
      # they depend on the data existing in the correct format in the sitemap
      # which we've already verified in controller tests
    end
  end

  defp add_country_with_data(_) do
    country = insert(:country, %{slug: "d"})

    federal_state =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "brandenburg",
        name: "Brandenburg"
      })

    city =
      insert(:city, %{
        parent_location_id: country.id,
        slug: "berlin",
        name: "Berlin"
      })

    school =
      insert(:school, %{
        parent_location_id: city.id,
        slug: "sample-school",
        name: "Sample School"
      })

    # Add a holiday type for testing
    holiday_type =
      insert(:holiday_or_vacation_type, %{
        name: "Test Holiday",
        country_location_id: country.id
      })

    # Add periods for federal state
    create_period(%{
      is_public_holiday: true,
      is_valid_for_everybody: true,
      location_id: federal_state.id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(@current_year, 5, 1),
      ends_on: Date.new!(@current_year, 5, 1),
      display_priority: 1,
      created_by_email_address: "test@example.com"
    })

    # Create a bridge day for the current year
    create_period(%{
      is_public_holiday: false,
      is_valid_for_everybody: true,
      location_id: federal_state.id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(@current_year, 4, 30),
      ends_on: Date.new!(@current_year, 4, 30),
      display_priority: 1,
      created_by_email_address: "test@example.com"
    })

    # Periods for city - current year
    create_period(%{
      is_public_holiday: true,
      location_id: city.id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(@current_year, 6, 1),
      ends_on: Date.new!(@current_year, 6, 5),
      display_priority: 1,
      created_by_email_address: "test@example.com"
    })

    # Periods for city - next year
    create_period(%{
      is_public_holiday: true,
      location_id: city.id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(@next_year, 6, 1),
      ends_on: Date.new!(@next_year, 6, 5),
      display_priority: 1,
      created_by_email_address: "test@example.com"
    })

    # Periods for school
    create_period(%{
      is_public_holiday: true,
      location_id: school.id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: Date.new!(@current_year, 7, 1),
      ends_on: Date.new!(@current_year, 7, 31),
      display_priority: 1,
      created_by_email_address: "test@example.com"
    })

    {:ok,
     %{
       country: country,
       federal_state: federal_state,
       city: city,
       school: school
     }}
  end

  defp create_period(attrs) do
    {:ok, period} = MehrSchulferien.Periods.create_period(attrs)
    period
  end
end
