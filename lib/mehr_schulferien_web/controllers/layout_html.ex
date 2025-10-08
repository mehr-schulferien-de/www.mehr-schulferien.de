defmodule MehrSchulferienWeb.LayoutHTML do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "layout"

  # Basic view imports
  # Import convenience functions from controllers
  import Phoenix.Controller,
    only: [view_module: 1, view_template: 1]

  import Phoenix.View, only: [render_existing: 3, render: 3]

  use PhoenixHTMLHelpers

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  alias MehrSchulferienWeb.ViewHelpers

  # Import shared components for unified design
  import MehrSchulferienWeb.Shared.TypographyComponent

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
