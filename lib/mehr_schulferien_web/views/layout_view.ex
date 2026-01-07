defmodule MehrSchulferienWeb.LayoutView do
  use MehrSchulferienWeb, :view
  import MehrSchulferienWeb.NavigationComponent

  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferienWeb.NavigationHelper

  @doc """
  Returns the layout template file.

  All pages now use the full modern layout with navigation and footer.
  The css_framework parameter is deprecated and no longer needed.
  """
  def select_layout_template(_conn, _assigns) do
    "app_tailwind_full.html"
  end

  @doc """
  Checks if the current page matches a federal state vacation page with a specific year.
  Used to disable menu items when viewing the same state's vacation page.

  Returns true if the current path matches the format:
  /ferien/:country_slug/bundesland/:federal_state_slug/:year
  and the federal_state_slug and year match the parameters.
  """
  def is_current_page_for_federal_state?(conn, federal_state_slug, year) do
    case conn.path_info do
      ["ferien", _country_slug, "bundesland", state_slug, year_str] ->
        state_slug == federal_state_slug && year_str == to_string(year)

      _ ->
        false
    end
  end

  @doc """
  Checks if the current page matches a federal state bridge days page with a specific year.
  Used to disable menu items when viewing the same state's bridge days page.

  Returns true if the current path matches the format:
  /brueckentage/:country_slug/bundesland/:federal_state_slug/:year
  and the federal_state_slug and year match the parameters.
  """
  def is_current_bridge_days_page_for_federal_state?(conn, federal_state_slug, year) do
    case conn.path_info do
      ["brueckentage", _country_slug, "bundesland", state_slug, year_str] ->
        state_slug == federal_state_slug && year_str == to_string(year)

      _ ->
        false
    end
  end

  @doc """
  Checks if the current page matches an Urlaubsplaner page for a specific federal state.
  Used to disable menu items when viewing the same state's vacation planner page.

  Returns true if the current path matches the format:
  /urlaubsplaner/:federal_state_slug/:days/:year
  or /urlaubsplaner-guenstig/:federal_state_slug/:days/:year
  """
  def is_current_urlaubsplaner_page_for_federal_state?(conn, federal_state_slug) do
    case conn.path_info do
      ["urlaubsplaner", state_slug, _days, _year] ->
        state_slug == federal_state_slug

      ["urlaubsplaner-guenstig", state_slug, _days, _year] ->
        state_slug == federal_state_slug

      _ ->
        false
    end
  end

  @doc """
  Gets the navigation years (current and next) based on today's date from the connection.
  """
  def get_navigation_assigns(conn) do
    today = DateHelpers.get_today_or_custom_date(conn)
    {current_year, next_year} = NavigationHelper.get_navigation_years(today)

    %{
      today: today,
      current_year: current_year,
      next_year: next_year
    }
  end
end
