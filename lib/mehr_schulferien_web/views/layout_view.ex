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
  Checks if the current page matches a navigation item for a specific federal state and year.
  Used to disable menu items when viewing the same state's page.

  The `page_type` parameter specifies which type of page to check:
  - `:ferien` - vacation pages (/ferien/:country/bundesland/:state/:year)
  - `:brueckentage` - bridge day pages (/brueckentage/:country/bundesland/:state/:year)
  - `:urlaubsplaner` - vacation planner pages (/urlaubsplaner/:state/:days/:year)
  """
  def is_current_page_for_federal_state?(conn, federal_state_slug, year) do
    matches_page?(conn.path_info, :ferien, federal_state_slug, year)
  end

  @doc """
  True on the evergreen (year-less) state page or the current-year page for
  that state. The nav's current-year tab links the evergreen page, so both
  count as "you are here".
  """
  def is_evergreen_or_current_year_state_page?(conn, federal_state_slug, current_year) do
    case conn.path_info do
      ["ferien", _, "bundesland", state] ->
        state == federal_state_slug

      _ ->
        is_current_page_for_federal_state?(conn, federal_state_slug, current_year)
    end
  end

  def is_current_bridge_days_page_for_federal_state?(conn, federal_state_slug, year) do
    matches_page?(conn.path_info, :brueckentage, federal_state_slug, year)
  end

  @doc """
  True on the evergreen (year-less) bridge day page or the current-year
  bridge day page for that state. The nav's current-year tab links the
  evergreen page, so both count as "you are here".
  """
  def is_evergreen_or_current_year_bridge_days_page?(conn, federal_state_slug, current_year) do
    case conn.path_info do
      ["brueckentage", _, "bundesland", state] ->
        state == federal_state_slug

      _ ->
        is_current_bridge_days_page_for_federal_state?(conn, federal_state_slug, current_year)
    end
  end

  def is_current_urlaubsplaner_page_for_federal_state?(conn, federal_state_slug, year) do
    matches_page?(conn.path_info, :urlaubsplaner, federal_state_slug, year)
  end

  defp matches_page?(["ferien", _, "bundesland", state, year_str], :ferien, expected_state, year) do
    state == expected_state && year_str == to_string(year)
  end

  defp matches_page?(
         ["brueckentage", _, "bundesland", state, year_str],
         :brueckentage,
         expected_state,
         year
       ) do
    state == expected_state && year_str == to_string(year)
  end

  defp matches_page?(["urlaubsplaner", state, _, year_str], :urlaubsplaner, expected_state, year) do
    state == expected_state && year_str == to_string(year)
  end

  defp matches_page?(
         ["urlaubsplaner-guenstig", state, _, year_str],
         :urlaubsplaner,
         expected_state,
         year
       ) do
    state == expected_state && year_str == to_string(year)
  end

  defp matches_page?(_path_info, _type, _state, _year), do: false

  @doc """
  Gets the navigation years (current and next) based on today's date from the connection.
  """
  def get_navigation_assigns(conn) do
    today = DateHelpers.get_today_or_custom_date(conn)
    {current_year, next_year, third_year} = NavigationHelper.get_navigation_years(today)

    %{
      today: today,
      current_year: current_year,
      next_year: next_year,
      third_year: third_year
    }
  end
end
