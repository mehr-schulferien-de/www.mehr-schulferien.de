defmodule MehrSchulferienWeb.LayoutView do
  use MehrSchulferienWeb, :view
  import Phoenix.HTML.Link
  import MehrSchulferienWeb.NavigationComponent

  @doc """
  Determines whether to use Bootstrap CSS (legacy) or Tailwind CSS (new).
  Now always returns false as Tailwind is the default.
  Kept for backwards compatibility.
  """
  def use_bootstrap?(_conn, _assigns) do
    false
  end

  @doc """
  Returns the appropriate layout template file based on the current CSS framework.
  Now always returns Tailwind layout.
  """
  def select_layout_template(_conn, assigns) do
    if Map.get(assigns, :css_framework) == :tailwind_new do
      "app_tailwind_full.html"
    else
      "app_tailwind_minimal.html"
    end
  end

  @doc """
  Checks if the current page matches a federal state page with a specific year.
  Used to disable menu items when viewing the same state's page.

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
end
