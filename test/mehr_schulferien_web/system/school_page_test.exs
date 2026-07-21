defmodule MehrSchulferienWeb.SchoolPageSystemTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest

  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers
  alias MehrSchulferienWeb.TestRouteHelpers

  @current_year Date.utc_today().year
  @next_year @current_year + 1
  @past_year @current_year - 2

  setup %{conn: conn} do
    {:ok, %{conn: conn}}
  end

  describe "school page" do
    setup [:add_school_with_periods]

    test "shows the school page with current year data", %{
      conn: conn,
      country: country,
      school: school
    } do
      conn =
        get(
          conn,
          TestRouteHelpers.school_path(conn, :show, country.slug, school.slug)
        )

      # Verify basic page content
      assert html_response(conn, 200) =~ "Schulferien #{school.name}"

      # Check that the periods table exists for current school year
      # Dynamically determine current school year based on current date
      current_school_year =
        if Date.utc_today().month >= 8, do: @current_year, else: @current_year - 1

      assert html_response(conn, 200) =~
               "Schuljahr #{current_school_year}/#{current_school_year + 1}"

      # Check for calendar months based on the current school year
      # The template shows months for the current and next school year
      # Current school year runs from August to July of the following year
      if Date.utc_today().month >= 8 do
        # We're after August, so current school year is @current_year/@current_year+1
        # Should show Aug-Dec of @current_year and Jan-Jul of @next_year
        assert html_response(conn, 200) =~ "August #{@current_year}"
        assert html_response(conn, 200) =~ "Dezember #{@current_year}"
        assert html_response(conn, 200) =~ "Januar #{@next_year}"
        assert html_response(conn, 200) =~ "Juli #{@next_year}"

        # Next school year (@next_year/@next_year+1) should also be shown
        assert html_response(conn, 200) =~ "August #{@next_year}"
        assert html_response(conn, 200) =~ "Dezember #{@next_year}"
      else
        # We're before August, so current school year is @current_year-1/@current_year
        # Should show Aug-Dec of @current_year-1 and Jan-Jul of @current_year
        assert html_response(conn, 200) =~ "August #{@current_year - 1}"
        assert html_response(conn, 200) =~ "Dezember #{@current_year - 1}"
        assert html_response(conn, 200) =~ "Januar #{@current_year}"
        assert html_response(conn, 200) =~ "Juli #{@current_year}"

        # Next school year (@current_year/@next_year) should also be shown
        assert html_response(conn, 200) =~ "August #{@current_year}"
        assert html_response(conn, 200) =~ "Dezember #{@current_year}"
        assert html_response(conn, 200) =~ "Januar #{@next_year}"
        assert html_response(conn, 200) =~ "Juli #{@next_year}"
      end
    end

    test "shows correct FAQ sections with only current year question", %{
      conn: conn,
      country: country,
      school: school
    } do
      conn =
        get(
          conn,
          TestRouteHelpers.school_path(conn, :show, country.slug, school.slug)
        )

      # Check that the FAQ section is present
      assert html_response(conn, 200) =~ "Ferien FAQ"

      # Check the current school year question exists
      # In July 2025, the current school year is 2024 (school year 2024/2025)
      current_school_year =
        if Date.utc_today().month >= 8, do: @current_year, else: @current_year - 1

      assert html_response(conn, 200) =~ "Schulfrei in der #{school.name} #{current_school_year}"

      # Check that the next/future year question doesn't exist
      refute html_response(conn, 200) =~ "Schulfrei in der #{school.name} #{@next_year}"

      # Check that the standard daily questions exist
      assert html_response(conn, 200) =~ "Ist heute schulfrei in der #{school.name}?"
      assert html_response(conn, 200) =~ "Ist morgen schulfrei in der #{school.name}?"

      # Check for the next vacation question
      assert html_response(conn, 200) =~
               "Wann sind die nächsten Schulferien in der #{school.name}?"
    end

    test "redirects from year-specific URL to base URL", %{
      conn: conn,
      country: country,
      school: school
    } do
      conn =
        get(
          conn,
          TestRouteHelpers.school_path(conn, :show_year, country.slug, school.slug, @current_year)
        )

      assert redirected_to(conn, 301) =~
               TestRouteHelpers.school_path(
                 conn,
                 :show,
                 country.slug,
                 school.slug
               )
    end

    test "redirects from past year URL to base URL", %{
      conn: conn,
      country: country,
      school: school
    } do
      conn =
        get(
          conn,
          TestRouteHelpers.school_path(conn, :show_year, country.slug, school.slug, @past_year)
        )

      # Year-specific URLs always redirect to base URL
      assert redirected_to(conn, 301) =~
               TestRouteHelpers.school_path(
                 conn,
                 :show,
                 country.slug,
                 school.slug
               )
    end

    test "shows wiki notice with edit and delete links", %{
      conn: conn,
      country: country,
      school: school
    } do
      conn =
        get(
          conn,
          TestRouteHelpers.school_path(conn, :show, country.slug, school.slug)
        )

      html = html_response(conn, 200)

      # Verify the wiki notice is present
      assert html =~ "Wiki-Seite"
      assert html =~ "Community aus Freiwilligen gepflegte Informationen"
      assert html =~ "nicht offiziell"
      assert html =~ "Im Zweifel bitte direkt bei der jeweiligen Schule nachfragen"

      # Verify edit/delete link is present
      assert html =~ "Eintrag bearbeiten oder löschen"
      assert html =~ "/wiki/schools/#{school.slug}/edit"
    end
  end

  describe "school page meta (CTR: navigational searchers need a reason to click)" do
    setup [:add_school_with_periods]

    test "title leads with the school name and the school year", %{
      conn: conn,
      country: country,
      school: school
    } do
      conn = get(conn, TestRouteHelpers.school_path(conn, :show, country.slug, school.slug))

      current_school_year =
        if Date.utc_today().month >= 8, do: @current_year, else: @current_year - 1

      assert html_response(conn, 200) =~
               "#{school.name}: Ferien & freie Tage #{current_school_year}/#{current_school_year + 1}"
    end

    test "meta description leads with the next vacation dates", %{
      conn: conn,
      country: country,
      school: school
    } do
      # Pin the clock to just before the autumn vacation of the current
      # school year so "next vacation" is deterministic.
      current_school_year =
        if Date.utc_today().month >= 8, do: @current_year, else: @current_year - 1

      conn =
        get(
          conn,
          TestRouteHelpers.school_path(conn, :show, country.slug, school.slug) <>
            "?today=01.10.#{current_school_year}"
        )

      response = html_response(conn, 200)
      assert response =~ "Nächste Ferien"
      assert response =~ "Herbstferien"
    end
  end

  defp add_school_with_periods(_) do
    # Create the location hierarchy
    country = get_or_create_deutschland()

    federal_state =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "brandenburg",
        name: "Brandenburg"
      })

    county =
      insert(:county, %{
        parent_location_id: federal_state.id,
        slug: "landkreis-berlin",
        name: "Landkreis Berlin"
      })

    city =
      insert(:city, %{
        parent_location_id: county.id,
        slug: "berlin",
        name: "Berlin"
      })

    school =
      insert(:school, %{
        parent_location_id: city.id,
        slug: "paul-schneider-schule",
        name: "Paul-Schneider-Schule"
      })

    # Create an address for the school
    insert(:address, %{
      school_location_id: school.id,
      street: "Schulstraße 1",
      zip_code: "10115",
      city: "Berlin",
      email_address: "info@paul-schneider-schule.de",
      phone_number: "+49 30 123456",
      homepage_url: "https://www.paul-schneider-schule.de"
    })

    # Create vacation periods for current year
    holiday_types = [
      insert(:holiday_or_vacation_type, %{name: "Winter", colloquial: "Winterferien"}),
      insert(:holiday_or_vacation_type, %{name: "Oster", colloquial: "Osterferien"}),
      insert(:holiday_or_vacation_type, %{name: "Sommer", colloquial: "Sommerferien"}),
      insert(:holiday_or_vacation_type, %{name: "Herbst", colloquial: "Herbstferien"}),
      insert(:holiday_or_vacation_type, %{name: "Weihnachts", colloquial: "Weihnachtsferien"})
    ]

    # Current school year periods (for FAQ logic)
    # Since we're in July 2025, current school year is 2024/2025
    current_school_year =
      if Date.utc_today().month >= 8, do: @current_year, else: @current_year - 1

    [
      # Autumn (school year start)
      {3, Date.new!(current_school_year, 10, 23), Date.new!(current_school_year, 11, 3)},
      # Christmas extending to next year
      {4, Date.new!(current_school_year, 12, 21), Date.new!(current_school_year + 1, 1, 5)},
      # Winter
      {0, Date.new!(current_school_year + 1, 2, 1), Date.new!(current_school_year + 1, 2, 10)},
      # Easter
      {1, Date.new!(current_school_year + 1, 4, 3), Date.new!(current_school_year + 1, 4, 14)},
      # Summer
      {2, Date.new!(current_school_year + 1, 7, 13), Date.new!(current_school_year + 1, 8, 25)}
    ]
    |> add_periods(holiday_types, federal_state.id)

    # Next school year periods
    next_school_year = current_school_year + 1

    [
      # Autumn (next school year start)
      {3, Date.new!(next_school_year, 10, 20), Date.new!(next_school_year, 11, 1)},
      # Christmas extending to following year
      {4, Date.new!(next_school_year, 12, 20), Date.new!(next_school_year + 1, 1, 6)},
      # Winter
      {0, Date.new!(next_school_year + 1, 2, 5), Date.new!(next_school_year + 1, 2, 10)},
      # Easter
      {1, Date.new!(next_school_year + 1, 3, 25), Date.new!(next_school_year + 1, 4, 5)},
      # Summer extending beyond July
      {2, Date.new!(next_school_year + 1, 7, 18), Date.new!(next_school_year + 1, 8, 28)}
    ]
    |> add_periods(holiday_types, federal_state.id)

    # Add public holidays
    add_public_holiday_periods(federal_state.id)

    {:ok,
     %{
       country: country,
       federal_state: federal_state,
       county: county,
       city: city,
       school: school
     }}
  end

  defp add_periods(period_data, holiday_types, location_id) do
    for {type_index, starts_on, ends_on} <- period_data do
      holiday_type = Enum.at(holiday_types, type_index)

      create_period(%{
        created_by_email_address: "test@example.com",
        location_id: location_id,
        holiday_or_vacation_type_id: holiday_type.id,
        starts_on: starts_on,
        ends_on: ends_on,
        is_school_vacation: true,
        is_valid_for_students: true
      })
    end
  end

  defp add_public_holiday_periods(location_id) do
    holiday_type =
      insert(:holiday_or_vacation_type, %{
        name: "Feiertag",
        colloquial: "Feiertag",
        default_is_public_holiday: true,
        default_is_school_vacation: false
      })

    # Current year public holidays
    [
      # New Year
      Date.new!(@current_year, 1, 1),
      # Good Friday
      Date.new!(@current_year, 4, 7),
      # Easter Monday
      Date.new!(@current_year, 4, 10),
      # Labor Day
      Date.new!(@current_year, 5, 1),
      # Christmas
      Date.new!(@current_year, 12, 25),
      # Boxing Day
      Date.new!(@current_year, 12, 26)
    ]
    |> Enum.each(fn date ->
      create_period(%{
        created_by_email_address: "test@example.com",
        location_id: location_id,
        holiday_or_vacation_type_id: holiday_type.id,
        starts_on: date,
        ends_on: date,
        is_public_holiday: true,
        is_valid_for_everybody: true
      })
    end)

    # Next year public holidays
    [
      # New Year
      Date.new!(@next_year, 1, 1),
      # Good Friday
      Date.new!(@next_year, 3, 29),
      # Easter Monday
      Date.new!(@next_year, 4, 1),
      # Labor Day
      Date.new!(@next_year, 5, 1)
    ]
    |> Enum.each(fn date ->
      create_period(%{
        created_by_email_address: "test@example.com",
        location_id: location_id,
        holiday_or_vacation_type_id: holiday_type.id,
        starts_on: date,
        ends_on: date,
        is_public_holiday: true,
        is_valid_for_everybody: true
      })
    end)
  end

  defp create_period(attrs) do
    {:ok, period} = MehrSchulferien.Periods.create_period(attrs)
    period
  end
end
