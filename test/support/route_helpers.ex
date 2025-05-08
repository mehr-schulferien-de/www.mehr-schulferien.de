defmodule MehrSchulferienWeb.TestRouteHelpers do
  @moduledoc """
  Helper functions for system tests to use the correct routes during the
  SEO URL structure transition period.
  """

  alias MehrSchulferienWeb.Router.Helpers, as: Routes

  def school_path(conn, action, country_slug, school_slug, year \\ nil) do
    case action do
      :show ->
        Routes.school_path(conn, :show, country_slug, school_slug)

      :show_year when is_binary(year) or is_integer(year) ->
        Routes.school_path(conn, :show_year, country_slug, school_slug, year)

      _ ->
        Routes.school_path(conn, action, country_slug, school_slug)
    end
  end

  def school_vcard_path(conn, :download, country_slug \\ nil, school_slug) do
    if country_slug do
      # New SEO-friendly path
      Routes.school_vcard_path(conn, :download, country_slug, school_slug)
    else
      # Legacy path - use direct URL instead of helper
      "/schule/#{school_slug}/vcard"
    end
  end

  def city_path(conn, action, country_slug, city_slug, year \\ nil) do
    case action do
      :show ->
        Routes.city_path(conn, :show, country_slug, city_slug)

      :show_year when is_binary(year) or is_integer(year) ->
        Routes.city_path(conn, :show_year, country_slug, city_slug, year)

      _ ->
        Routes.city_path(conn, action, country_slug, city_slug)
    end
  end

  def federal_state_path(conn, action, country_slug, federal_state_slug, year_or_type \\ nil) do
    case action do
      :show ->
        Routes.federal_state_path(conn, :show, country_slug, federal_state_slug)

      :show_year when is_binary(year_or_type) or is_integer(year_or_type) ->
        Routes.federal_state_path(
          conn,
          :show_year,
          country_slug,
          federal_state_slug,
          year_or_type
        )

      :show_holiday_or_vacation_type when is_binary(year_or_type) ->
        Routes.federal_state_path(
          conn,
          :show_holiday_or_vacation_type,
          country_slug,
          federal_state_slug,
          year_or_type
        )

      :county_show ->
        Routes.federal_state_path(conn, :county_show, country_slug, federal_state_slug)

      _ ->
        Routes.federal_state_path(conn, action, country_slug, federal_state_slug)
    end
  end
end
