defmodule MehrSchulferienWeb.RedirectController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferienWeb.Router.Helpers, as: Routes

  # City redirects
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

  # Federal state redirects
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

  # School redirects
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

  # Public holiday redirects
  def redirect_public_holiday(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "holiday_or_vacation_type_slug" => holiday_or_vacation_type_slug
      }) do
    conn
    |> redirect(
      to:
        Routes.public_holiday_path(
          conn,
          :show_within_federal_state,
          country_slug,
          federal_state_slug,
          holiday_or_vacation_type_slug
        )
    )
  end

  # Bridge day redirects
  def redirect_bridge_days(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    # Get the current year
    today = MehrSchulferien.Calendars.DateHelpers.today_berlin()
    current_year = today.year

    conn
    |> redirect(
      to: "/land/#{country_slug}/bundesland/#{federal_state_slug}/brueckentage/#{current_year}"
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
