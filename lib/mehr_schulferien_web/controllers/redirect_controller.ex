defmodule MehrSchulferienWeb.RedirectController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferienWeb.Router.Helpers, as: Routes

  # ============== NEW: /land/ to /ferien/ redirects for SEO ==============

  # City redirects from /land/ to /ferien/
  def redirect_land_city_year_to_ferien(conn, %{
        "country_slug" => country_slug,
        "city_slug" => city_slug,
        "year" => year
      }) do
    conn
    |> redirect(to: "/ferien/#{country_slug}/stadt/#{city_slug}/#{year}")
  end

  def redirect_land_city_to_ferien(conn, %{
        "country_slug" => country_slug,
        "city_slug" => city_slug
      }) do
    conn
    |> redirect(to: "/ferien/#{country_slug}/stadt/#{city_slug}")
  end

  # Federal state redirects from /land/ to /ferien/
  def redirect_land_federal_state_year_to_ferien(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    conn
    |> redirect(to: "/ferien/#{country_slug}/bundesland/#{federal_state_slug}/#{year}")
  end

  def redirect_land_federal_state_to_ferien(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    conn
    |> redirect(to: "/ferien/#{country_slug}/bundesland/#{federal_state_slug}")
  end

  def redirect_land_counties_and_cities_to_ferien(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    conn
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
    |> redirect(to: "/ferien/#{country_slug}/schule/#{school_slug}/#{year}")
  end

  def redirect_land_school_to_ferien(conn, %{
        "country_slug" => country_slug,
        "school_slug" => school_slug
      }) do
    conn
    |> redirect(to: "/ferien/#{country_slug}/schule/#{school_slug}")
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
    |> redirect(to: Routes.city_path(conn, :show_year, country_slug, city_slug, year))
  end

  def redirect_city(conn, %{"country_slug" => country_slug, "city_slug" => city_slug}) do
    conn
    |> redirect(to: Routes.city_path(conn, :show, country_slug, city_slug))
  end

  # Federal state redirects - these were already redirecting properly
  def redirect_federal_state_year(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    conn
    |> redirect(
      to: Routes.federal_state_path(conn, :show_year, country_slug, federal_state_slug, year)
    )
  end

  def redirect_federal_state(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    conn
    |> redirect(to: Routes.federal_state_path(conn, :show, country_slug, federal_state_slug))
  end

  def redirect_federal_state_category(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "holiday_or_vacation_type_slug" => holiday_or_vacation_type_slug
      }) do
    conn
    |> redirect(
      to:
        Routes.federal_state_path(
          conn,
          :show_holiday_or_vacation_type,
          country_slug,
          federal_state_slug,
          holiday_or_vacation_type_slug
        )
    )
  end

  # School redirects - these were already redirecting properly
  def redirect_school_year(conn, %{
        "country_slug" => country_slug,
        "school_slug" => school_slug,
        "year" => year
      }) do
    conn
    |> redirect(to: Routes.school_path(conn, :show_year, country_slug, school_slug, year))
  end

  def redirect_school(conn, %{"country_slug" => country_slug, "school_slug" => school_slug}) do
    conn
    |> redirect(to: Routes.school_path(conn, :show, country_slug, school_slug))
  end

  # Public holiday redirects - now redirects to federal state page
  def redirect_public_holiday(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "holiday_or_vacation_type_slug" => _holiday_or_vacation_type_slug
      }) do
    conn
    |> redirect(to: Routes.federal_state_path(conn, :show, country_slug, federal_state_slug))
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
    |> redirect(
      to:
        Routes.bridge_day_path(
          conn,
          :show_within_federal_state,
          country_slug,
          federal_state_slug,
          year
        )
    )
  end

  # Misc redirects
  def redirect_counties_and_cities(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    conn
    |> redirect(
      to: Routes.federal_state_path(conn, :county_show, country_slug, federal_state_slug)
    )
  end
end
