defmodule MehrSchulferienWeb.SchoolController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Blacklist, Calendars.DateHelpers, Config, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.ViewHelpers
  alias MehrSchulferienWeb.Helpers.UserAgentHelpers
  import MehrSchulferienWeb.LocationTrackingHelpers

  def show_year(conn, %{
        "country_slug" => country_slug,
        "school_slug" => school_slug,
        "year" => _year
      }) do
    case Locations.show_school_to_country_map_safe(country_slug, school_slug) do
      {:ok, %{country: country}} ->
        # Redirect to the school page without year (301 permanent redirect for SEO)
        conn
        |> put_status(:moved_permanently)
        |> redirect(to: ~p"/ferien/#{country.slug}/schule/#{school_slug}")

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(MehrSchulferienWeb.ErrorView)
        |> render("404.html")

      {:error, _} ->
        CH.render_not_found_or_empty_database(conn)
    end
  end

  def show(conn, %{"country_slug" => country_slug, "school_slug" => school_slug}) do
    case Locations.show_school_to_country_map_safe(country_slug, school_slug) do
      {:ok,
       %{
         country: country,
         federal_state: federal_state,
         county: county,
         city: city,
         school: school
       }} ->
        show_school_page(conn, country, federal_state, county, city, school)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(MehrSchulferienWeb.ErrorView)
        |> render("404.html")

      {:error, _} ->
        CH.render_not_found_or_empty_database(conn)
    end
  end

  defp show_school_page(conn, country, federal_state, county, city, school) do
    cond do
      # Check if school is quarantined
      Locations.school_quarantined?(school) ->
        render_quarantined_423(conn)

      # Check if school was updated during spam attack timeframe
      school_updated_during_spam_attack?(school) ->
        render_spam_affected_503(conn)

      true ->
        show_school_page_content(conn, country, federal_state, county, city, school)
    end
  end

  defp show_school_page_content(conn, country, federal_state, county, city, school) do
    # Filter blacklisted data from school address before display
    school = filter_blacklisted_address(school)

    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year

    # Determine current school year (starts in August)
    current_school_year = if today.month >= 8, do: current_year, else: current_year - 1
    next_school_year = current_school_year + 1

    location_ids = [country.id, federal_state.id, county.id, city.id, school.id]

    # Get all periods in one query from current school year start to next school year end
    {:ok, full_start} = Date.new(current_school_year, 8, 1)
    {:ok, full_end} = Date.new(next_school_year + 1, 7, 31)

    # Use the new SQL-based grouped query
    all_periods =
      MehrSchulferien.Periods.list_grouped_school_vacation_periods_v2(
        location_ids,
        full_start,
        full_end
      )

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
    combined_periods = all_periods ++ all_public_periods

    periods_with_duration =
      ViewHelpers.add_adjoining_duration_to_periods(all_periods, combined_periods)

    # Set the appropriate status code based on data availability
    conn = if has_data, do: conn, else: put_status(conn, 404)

    # Track school visit
    conn = track_location_visit(conn, "s", school.slug)

    # Get nearby schools
    nearby_schools = Locations.list_nearby_schools(school, 3000)

    # Get bewegliche Ferientage from this school and other schools with same zip code
    school_bewegliche_ferientage =
      MehrSchulferien.Periods.list_bewegliche_ferientage_for_school_in_range(
        school.id,
        full_start,
        full_end
      )

    # Get other schools with same zip code and their bewegliche ferientage
    other_schools_bewegliche_ferientage =
      if school.address && school.address.zip_code do
        # Get all schools with the same zip code (excluding current school)
        schools_same_zip = Locations.find_schools_by_same_zip_code(school)

        # Get bewegliche ferientage for each school and track which schools have them
        ferientage_with_schools =
          schools_same_zip
          |> Enum.flat_map(fn other_school ->
            MehrSchulferien.Periods.list_bewegliche_ferientage_for_school_in_range(
              other_school.id,
              full_start,
              full_end
            )
            |> Enum.map(fn period ->
              # Add school information to each period
              Map.put(period, :source_schools, [
                %{name: other_school.name, slug: other_school.slug}
              ])
            end)
          end)
          |> Enum.group_by(& &1.starts_on)
          |> Enum.map(fn {_date, periods} ->
            # Merge periods with same date, combining school info
            first_period = hd(periods)

            all_schools =
              periods
              |> Enum.flat_map(& &1.source_schools)
              |> Enum.uniq_by(& &1.slug)
              |> Enum.sort_by(& &1.name)

            Map.put(first_period, :source_schools, all_schools)
          end)
          |> Enum.reject(fn period ->
            # Exclude dates that the current school already has
            Enum.any?(school_bewegliche_ferientage, &(&1.starts_on == period.starts_on))
          end)
          |> Enum.sort_by(& &1.starts_on)

        ferientage_with_schools
      else
        []
      end

    # Get federal state limit information
    current_school_year_string = MehrSchulferien.Periods.get_school_year_for_date(today)

    ferientage_limit =
      MehrSchulferien.Periods.get_federal_state_ferientage_limit(
        federal_state.id,
        current_school_year_string
      )

    allows_bewegliche_ferientage =
      ferientage_limit && ferientage_limit.max_bewegliche_ferientage > 0

    # Get FAQ data
    faq_data = CH.list_faq_data(location_ids, today)

    # Detect if user is on Apple device
    is_apple_device = UserAgentHelpers.is_apple_device?(conn)

    render(
      conn,
      "show.html",
      %{
        country: country,
        federal_state: federal_state,
        county: county,
        city: city,
        school: school,
        periods: periods_with_duration,
        public_periods: all_public_periods,
        all_periods: all_periods ++ all_public_periods,
        current_school_year: current_school_year,
        next_school_year: next_school_year,
        years_with_data: years_with_data,
        today: today,
        has_data: has_data,
        nearby_schools: nearby_schools,
        is_apple_device: is_apple_device,
        school_bewegliche_ferientage: school_bewegliche_ferientage,
        other_schools_bewegliche_ferientage: other_schools_bewegliche_ferientage,
        allows_bewegliche_ferientage: allows_bewegliche_ferientage,
        ferientage_limit: ferientage_limit,
        current_school_year_string: current_school_year_string,
        school_contact_info_enabled: Config.school_contact_info_enabled?()
      }
      |> Map.merge(Map.new(faq_data))
    )
  end

  def documents_index(conn, %{"school_slug" => school_slug}) do
    # Get school information
    school = Locations.get_school_by_slug!(school_slug)
    # Filter blacklisted data from school address before display
    school = filter_blacklisted_address(school)
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
    # Use the grouped query directly
    vacation_periods =
      MehrSchulferien.Periods.list_grouped_school_vacation_periods_v2(
        location_ids,
        starts_on,
        ends_on
      )
      # Show next 3 vacations
      |> Enum.take(3)

    alias MehrSchulferienWeb.Helpers.SeoTitleHelper

    truncated_name = SeoTitleHelper.truncate_school_name(school.name)
    page_title = "Schulbriefe - #{truncated_name}"

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
      school_contact_info_enabled: Config.school_contact_info_enabled?()
    )
  end

  # Filters blacklisted fields from school's address
  defp filter_blacklisted_address(%{address: address} = school) when not is_nil(address) do
    filtered_address = Blacklist.filter_address(address)
    %{school | address: filtered_address}
  end

  defp filter_blacklisted_address(school), do: school

  # Check if school was updated during the spam attack window
  # Original: 15.01.2026 20:30-20:50 German time (CET = UTC+1)
  # Extended by 1 hour before and after to be safe (timezone buffer)
  # New window: 19:30-21:50 CET = 18:30-20:50 UTC
  defp school_updated_during_spam_attack?(school) do
    # Skip spam check in test environment (test schools get current timestamp)
    if Application.get_env(:mehr_schulferien, :env) == :test do
      false
    else
      case school.updated_at do
        nil ->
          false

        updated_at ->
          # Convert to UTC DateTime for comparison
          updated_utc = DateTime.from_naive!(updated_at, "Etc/UTC")

          # Spam attack window with 1-hour buffer on each side
          # 18:30-20:50 UTC = 19:30-21:50 CET (German time)
          {:ok, spam_start} = DateTime.new(~D[2026-01-15], ~T[18:30:00], "Etc/UTC")
          {:ok, spam_end} = DateTime.new(~D[2026-01-15], ~T[20:50:00], "Etc/UTC")

          DateTime.compare(updated_utc, spam_start) != :lt &&
            DateTime.compare(updated_utc, spam_end) != :gt
      end
    end
  end

  # Render 503 Service Unavailable for spam-affected schools
  # Retry-After tells Google to come back in 3 days (259200 seconds)
  defp render_spam_affected_503(conn) do
    conn
    |> put_status(:service_unavailable)
    |> put_resp_header("retry-after", "259200")
    |> put_view(MehrSchulferienWeb.ErrorHTML)
    |> render("503.html")
  end

  # Render 423 Locked for quarantined schools
  # Retry-After tells clients to come back in 7 days (604800 seconds)
  defp render_quarantined_423(conn) do
    conn
    |> put_status(:locked)
    |> put_resp_header("retry-after", "604800")
    |> put_view(MehrSchulferienWeb.ErrorHTML)
    |> render("423.html")
  end
end
