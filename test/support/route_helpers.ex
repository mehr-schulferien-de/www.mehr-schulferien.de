defmodule MehrSchulferienWeb.TestRouteHelpers do
  @moduledoc """
  Helper functions for system tests to use the correct routes using verified routes.
  Updated to use Phoenix verified routes instead of legacy Routes helpers.
  """

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  def school_path(_conn, action, country_slug, school_slug, year \\ nil) do
    case action do
      :show ->
        ~p"/ferien/#{country_slug}/schule/#{school_slug}"

      :show_year when is_binary(year) or is_integer(year) ->
        ~p"/ferien/#{country_slug}/schule/#{school_slug}/#{year}"

      _ ->
        ~p"/ferien/#{country_slug}/schule/#{school_slug}"
    end
  end

  def school_vcard_path(_conn, :download, country_slug \\ nil, school_slug) do
    if country_slug do
      # New SEO-friendly path
      ~p"/ferien/#{country_slug}/schule/#{school_slug}/vcard"
    else
      # Legacy path - direct URL
      "/schule/#{school_slug}/vcard"
    end
  end

  def city_path(_conn, action, country_slug, city_slug, year \\ nil) do
    case action do
      :show ->
        ~p"/ferien/#{country_slug}/stadt/#{city_slug}"

      :show_year when is_binary(year) or is_integer(year) ->
        ~p"/ferien/#{country_slug}/stadt/#{city_slug}/#{year}"

      _ ->
        ~p"/ferien/#{country_slug}/stadt/#{city_slug}"
    end
  end

  def federal_state_path(_conn, action, country_slug, federal_state_slug, year_or_type \\ nil) do
    case action do
      :show ->
        ~p"/ferien/#{country_slug}/bundesland/#{federal_state_slug}"

      :show_year when is_binary(year_or_type) or is_integer(year_or_type) ->
        ~p"/ferien/#{country_slug}/bundesland/#{federal_state_slug}/#{year_or_type}"

      :show_holiday_or_vacation_type when is_binary(year_or_type) ->
        # This might need adjustment based on actual route
        ~p"/ferien/#{country_slug}/bundesland/#{federal_state_slug}/#{year_or_type}"

      :county_show ->
        ~p"/ferien/#{country_slug}/bundesland/#{federal_state_slug}/landkreise-und-staedte"

      _ ->
        ~p"/ferien/#{country_slug}/bundesland/#{federal_state_slug}"
    end
  end
end
