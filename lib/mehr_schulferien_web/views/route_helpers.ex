defmodule MehrSchulferienWeb.RouteHelpers do
  @moduledoc """
  Helper functions for working with the new route structure while maintaining
  backward compatibility with old route paths.

  This module provides transition helpers to ensure all templates can be 
  smoothly migrated to the new URL structure.
  """

  alias MehrSchulferienWeb.Router.Helpers, as: Routes

  @doc """
  Returns the proper school path with the new route structure.
  """
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

  @doc """
  Returns the proper city path with the new route structure.
  """
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

  @doc """
  Returns the proper federal state path with the new route structure.
  """
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

      :county_show ->
        Routes.federal_state_path(conn, :county_show, country_slug, federal_state_slug)

      _ ->
        Routes.federal_state_path(conn, action, country_slug, federal_state_slug)
    end
  end

  @doc """
  Returns the proper country path with the new route structure.
  """
  def country_path(conn, action, country_slug) do
    Routes.country_path(conn, action, country_slug)
  end

  @doc """
  Returns the federal state path for old public holiday routes.
  This is for backward compatibility with old templates that may still use this helper.
  """
  def public_holiday_path(
        conn,
        _action,
        country_slug,
        federal_state_slug,
        _holiday_or_vacation_type_slug
      ) do
    # Redirect to federal state page for all public holiday related actions
    Routes.federal_state_path(conn, :show, country_slug, federal_state_slug)
  end

  @doc """
  Returns the proper bridge day path with the new route structure.
  """
  def bridge_day_path(conn, action, country_slug, federal_state_slug, year \\ nil) do
    case action do
      :index_within_federal_state ->
        Routes.bridge_day_path(
          conn,
          :index_within_federal_state,
          country_slug,
          federal_state_slug
        )

      :show_within_federal_state when is_binary(year) or is_integer(year) ->
        Routes.bridge_day_path(
          conn,
          :show_within_federal_state,
          country_slug,
          federal_state_slug,
          year
        )

      _ ->
        Routes.bridge_day_path(conn, action, country_slug, federal_state_slug)
    end
  end

  @doc """
  Returns the proper school vcard path with the new route structure.
  For backward compatibility, this supports both the legacy path and the new SEO-friendly path.
  """
  def school_vcard_path(conn, _action, country_slug \\ nil, school_slug) do
    # When both country_slug and school_slug are provided, use the new format
    if is_binary(country_slug) and country_slug != "" and is_binary(school_slug) and
         school_slug != "" do
      # Use the standard named helper for download with country_slug
      Routes.school_vcard_path(conn, :download, country_slug, school_slug)
    else
      # Handle legacy format - use the standard URL helpers without named routes
      slug = if is_binary(school_slug), do: school_slug, else: country_slug
      "/schule/#{slug}/vcard"
    end
  end
end
