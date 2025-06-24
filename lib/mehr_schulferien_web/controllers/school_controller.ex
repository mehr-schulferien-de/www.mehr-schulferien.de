defmodule MehrSchulferienWeb.SchoolController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.ViewHelpers

  def show_year(conn, %{
        "country_slug" => country_slug,
        "school_slug" => school_slug,
        "year" => year
      }) do
    %{country: country, federal_state: federal_state, county: county, city: city, school: school} =
      Locations.show_school_to_country_map(country_slug, school_slug)

    today = DateHelpers.get_today_or_custom_date(conn)
    location_ids = [country.id, federal_state.id, county.id, city.id, school.id]

    # Use shared logic to prepare show_year data (with school-specific extension)
    data = CH.prepare_show_year_data(location_ids, year, today, extend_to_next_july: true)

    # Calculate adjoining_duration for each period
    # This ensures display values reflect the current calculation
    periods_with_duration =
      Enum.map(data.periods, fn period ->
        days = Date.diff(period.ends_on, period.starts_on) + 1
        effective_duration = ViewHelpers.calculate_effective_duration(period, data.all_periods)
        difference = effective_duration - days
        Map.put(period, :adjoining_duration, difference)
      end)

    # Set the appropriate status code based on data availability
    conn = if data.has_data, do: conn, else: put_status(conn, 404)

    # Get nearby schools
    nearby_schools = Locations.list_nearby_schools(school, 3000)

    render(
      conn,
      "show_year.html",
      %{
        country: country,
        federal_state: federal_state,
        county: county,
        city: city,
        school: school,
        css_framework: :tailwind_new,
        periods: periods_with_duration,
        all_periods: data.all_periods,
        nearby_schools: nearby_schools
      }
      |> Map.merge(data)
      |> Map.merge(Map.new(data.faq_data))
    )
  end

  def show(conn, %{"country_slug" => country_slug, "school_slug" => school_slug}) do
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year

    redirect(conn,
      to:
        Routes.school_path(
          conn,
          :show_year,
          country_slug,
          school_slug,
          current_year
        )
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
