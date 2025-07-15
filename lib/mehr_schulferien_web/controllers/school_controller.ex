defmodule MehrSchulferienWeb.SchoolController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.ViewHelpers

  def show_year(conn, %{
        "country_slug" => country_slug,
        "school_slug" => school_slug,
        "year" => _year
      }) do
    %{country: country} =
      Locations.show_school_to_country_map(country_slug, school_slug)

    # Redirect to the school page without year (301 permanent redirect for SEO)
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/ferien/#{country.slug}/schule/#{school_slug}")
  end

  def show(conn, %{"country_slug" => country_slug, "school_slug" => school_slug}) do
    %{country: country, federal_state: federal_state, county: county, city: city, school: school} =
      Locations.show_school_to_country_map(country_slug, school_slug)

    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year

    # Determine current school year (starts in August)
    current_school_year = if today.month >= 8, do: current_year, else: current_year - 1
    next_school_year = current_school_year + 1

    location_ids = [country.id, federal_state.id, county.id, city.id, school.id]

    # Get all periods in one query from current school year start to next school year end
    {:ok, full_start} = Date.new(current_school_year, 8, 1)
    {:ok, full_end} = Date.new(next_school_year + 1, 7, 31)

    all_periods =
      MehrSchulferien.Periods.list_school_vacation_periods(location_ids, full_start, full_end)

    all_public_periods =
      MehrSchulferien.Periods.list_public_periods(location_ids, full_start, full_end)

    # Check if we have data
    has_data = length(all_periods) > 0

    # Get years with data for navigation
    years_with_data =
      all_periods
      |> Enum.map(& &1.starts_on.year)
      |> Enum.uniq()
      |> Enum.sort()

    # Calculate adjoining_duration for each period
    periods_with_duration =
      Enum.map(all_periods, fn period ->
        days = Date.diff(period.ends_on, period.starts_on) + 1

        effective_duration =
          ViewHelpers.calculate_effective_duration(period, all_periods ++ all_public_periods)

        difference = effective_duration - days
        Map.put(period, :adjoining_duration, difference)
      end)

    # Set the appropriate status code based on data availability
    conn =
      if has_data do
        conn
      else
        put_status(conn, 404)
      end

    # Get nearby schools
    nearby_schools = Locations.list_nearby_schools(school, 3000)

    # Get FAQ data
    faq_data = CH.list_faq_data(location_ids, today)

    render(
      conn,
      "show.html",
      %{
        country: country,
        federal_state: federal_state,
        county: county,
        city: city,
        school: school,
        css_framework: :tailwind_new,
        periods: periods_with_duration,
        public_periods: all_public_periods,
        all_periods: all_periods ++ all_public_periods,
        current_school_year: current_school_year,
        next_school_year: next_school_year,
        years_with_data: years_with_data,
        today: today,
        has_data: has_data,
        nearby_schools: nearby_schools
      }
      |> Map.merge(Map.new(faq_data))
    )
  end

  def documents_index(conn, %{"school_slug" => school_slug}) do
    # Get school information
    school = Locations.get_school_by_slug!(school_slug)
    city = Locations.get_location!(school.parent_location_id)
    county = Locations.get_location!(city.parent_location_id)
    federal_state = Locations.get_location!(county.parent_location_id)
    country = Locations.get_location!(federal_state.parent_location_id)

    # Get current year for reference
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year

    # Get vacation data
    location_ids = [country.id, federal_state.id, county.id, city.id, school.id]
    # Get vacations for next 6 months
    starts_on = today
    ends_on = Date.add(today, 180)

    # Get only school vacation periods (not public holidays)
    vacation_periods =
      MehrSchulferien.Periods.Query.list_school_vacation_periods(location_ids, starts_on, ends_on)
      # Show next 3 vacations
      |> Enum.take(3)

    page_title = "Entschuldigungsschreiben und Beurlaubungen - #{school.name}"

    page_description =
      "Erstellen Sie kostenlos Entschuldigungsschreiben, Beurlaubungen und Sportbefreiungen für #{school.name}. Einfache Formulare, professionelle PDFs zum Download."

    render(conn, "documents_index.html",
      school: school,
      city: city,
      county: county,
      federal_state: federal_state,
      country: country,
      current_year: current_year,
      vacation_periods: vacation_periods,
      today: today,
      page_title: page_title,
      page_description: page_description,
      og_image: "/images/entschuldigung-dummy.png",
      css_framework: :tailwind_new
    )
  end
end
