defmodule MehrSchulferienWeb.RedirectController do
  use MehrSchulferienWeb, :controller

  # Note: This controller has been fully migrated to use ~p sigil

  # ============== NEW: /cities/ to /ferien/ redirects ==============
  #
  # The old URL format used zip codes in the slug: /cities/33619-bielefeld
  # where 33619 is the postal code (PLZ) for that part of Bielefeld.
  # We need to look up the city by zip code and redirect to the proper city slug.

  # Old /cities/ URL pattern redirects
  def redirect_cities(conn, %{"city_slug" => old_city_slug}) do
    # Extract the zip code from the old slug (format: "33619-bielefeld")
    case String.split(old_city_slug, "-", parts: 2) do
      [zip_code, _name] ->
        # Look up the city by zip code
        city = get_city_by_zip_code!(zip_code)

        # Navigate up the hierarchy to find the country
        county = MehrSchulferien.Locations.get_location!(city.parent_location_id)
        federal_state = MehrSchulferien.Locations.get_location!(county.parent_location_id)
        country = MehrSchulferien.Locations.get_location!(federal_state.parent_location_id)

        conn
        |> put_status(:moved_permanently)
        |> redirect(to: "/ferien/#{country.slug}/stadt/#{city.slug}")

      _ ->
        # Fallback if slug format is unexpected
        raise Ecto.NoResultsError, queryable: MehrSchulferien.Locations.Location
    end
  end

  def redirect_cities_with_year(conn, %{"city_slug" => old_city_slug, "year" => year}) do
    # Extract the zip code from the old slug (format: "33619-bielefeld")
    case String.split(old_city_slug, "-", parts: 2) do
      [zip_code, _name] ->
        # Look up the city by zip code
        city = get_city_by_zip_code!(zip_code)

        # Navigate up the hierarchy to find the country
        county = MehrSchulferien.Locations.get_location!(city.parent_location_id)
        federal_state = MehrSchulferien.Locations.get_location!(county.parent_location_id)
        country = MehrSchulferien.Locations.get_location!(federal_state.parent_location_id)

        conn
        |> put_status(:moved_permanently)
        |> redirect(to: "/ferien/#{country.slug}/stadt/#{city.slug}/#{year}")

      _ ->
        # Fallback if slug format is unexpected
        raise Ecto.NoResultsError, queryable: MehrSchulferien.Locations.Location
    end
  end

  # Helper function to find a city by zip code
  defp get_city_by_zip_code!(zip_code) do
    import Ecto.Query
    alias MehrSchulferien.Locations.Location
    alias MehrSchulferien.Maps.{ZipCode, ZipCodeMapping}
    alias MehrSchulferien.Repo

    # Find the zip code - use limit 1 to handle duplicates
    zip_query = from z in ZipCode, where: z.value == ^zip_code, limit: 1
    zip = Repo.one!(zip_query)

    # Find the city associated with this zip code
    city_query =
      from l in Location,
        join: zcm in ZipCodeMapping,
        on: zcm.location_id == l.id,
        where: zcm.zip_code_id == ^zip.id and l.is_city == true,
        limit: 1

    Repo.one!(city_query)
  end

  # ============== NEW: /land/ to /ferien/ redirects for SEO ==============

  # City redirects from /land/ to /ferien/
  def redirect_land_city_year_to_ferien(conn, %{
        "country_slug" => country_slug,
        "city_slug" => city_slug,
        "year" => year
      }) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: "/ferien/#{country_slug}/stadt/#{city_slug}/#{year}")
  end

  def redirect_land_city_to_ferien(conn, %{
        "country_slug" => country_slug,
        "city_slug" => city_slug
      }) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: "/ferien/#{country_slug}/stadt/#{city_slug}")
  end

  # Federal state redirects from /land/ to /ferien/
  def redirect_land_federal_state_year_to_ferien(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: "/ferien/#{country_slug}/bundesland/#{federal_state_slug}/#{year}")
  end

  def redirect_land_federal_state_to_ferien(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: "/ferien/#{country_slug}/bundesland/#{federal_state_slug}")
  end

  def redirect_land_counties_and_cities_to_ferien(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(
      to: "/ferien/#{country_slug}/bundesland/#{federal_state_slug}/landkreise-und-staedte"
    )
  end

  # School redirects from /land/ to /ferien/
  def redirect_land_school_year_to_ferien(conn, %{
        "country_slug" => country_slug,
        "school_slug" => school_slug,
        "year" => year
      }) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: "/ferien/#{country_slug}/schule/#{school_slug}/#{year}")
  end

  def redirect_land_school_to_ferien(conn, %{
        "country_slug" => country_slug,
        "school_slug" => school_slug
      }) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: "/ferien/#{country_slug}/schule/#{school_slug}")
  end

  # Legacy /schools/ redirects (English URL pattern)
  def redirect_schools(conn, %{"school_slug" => school_slug}) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/ferien/d/schule/#{school_slug}")
  end

  def redirect_schools_with_year(conn, %{"school_slug" => school_slug, "year" => _year}) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/ferien/d/schule/#{school_slug}")
  end

  # Bridge days redirects from /land/ to /ferien/
  def redirect_land_bridge_days_to_ferien(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    # Get the current year
    today = MehrSchulferien.Calendars.DateHelpers.today_berlin()
    current_year = today.year

    conn
    |> redirect(
      to: "/brueckentage/#{country_slug}/bundesland/#{federal_state_slug}/#{current_year}"
    )
  end

  def redirect_land_bridge_days_year_to_ferien(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: "/brueckentage/#{country_slug}/bundesland/#{federal_state_slug}/#{year}")
  end

  # ============== LEGACY redirects that can now redirect to /ferien/ ==============

  # City redirects - these were already redirecting properly
  def redirect_city_year(conn, %{
        "country_slug" => country_slug,
        "city_slug" => city_slug,
        "year" => year
      }) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/ferien/#{country_slug}/stadt/#{city_slug}/#{year}")
  end

  def redirect_city(conn, %{"country_slug" => country_slug, "city_slug" => city_slug}) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/ferien/#{country_slug}/stadt/#{city_slug}")
  end

  # Federal state redirects - these were already redirecting properly
  def redirect_federal_state_year(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/ferien/#{country_slug}/bundesland/#{federal_state_slug}/#{year}")
  end

  def redirect_federal_state(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/ferien/#{country_slug}/bundesland/#{federal_state_slug}")
  end

  def redirect_federal_state_category(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "holiday_or_vacation_type_slug" => _holiday_or_vacation_type_slug
      }) do
    # Note: :show_holiday_or_vacation_type route doesn't exist in current router
    # Redirecting to federal state page instead
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/ferien/#{country_slug}/bundesland/#{federal_state_slug}")
  end

  # School redirects - these were already redirecting properly
  def redirect_school_year(conn, %{
        "country_slug" => country_slug,
        "school_slug" => school_slug,
        "year" => year
      }) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/ferien/#{country_slug}/schule/#{school_slug}/#{year}")
  end

  def redirect_school(conn, %{"country_slug" => country_slug, "school_slug" => school_slug}) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/ferien/#{country_slug}/schule/#{school_slug}")
  end

  # Public holiday redirects - now redirects to federal state page
  def redirect_public_holiday(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "holiday_or_vacation_type_slug" => _holiday_or_vacation_type_slug
      }) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/ferien/#{country_slug}/bundesland/#{federal_state_slug}")
  end

  # Bridge day redirects - update to use new /brueckentage/ URLs
  def redirect_bridge_days(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    # Get the current year
    today = MehrSchulferien.Calendars.DateHelpers.today_berlin()
    current_year = today.year

    conn
    |> redirect(
      to: "/brueckentage/#{country_slug}/bundesland/#{federal_state_slug}/#{current_year}"
    )
  end

  def redirect_bridge_days_year(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/brueckentage/#{country_slug}/bundesland/#{federal_state_slug}/#{year}")
  end

  # Misc redirects
  def redirect_counties_and_cities(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(
      to: ~p"/ferien/#{country_slug}/bundesland/#{federal_state_slug}/landkreise-und-staedte"
    )
  end
end
