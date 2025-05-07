defmodule MehrSchulferienWeb.LayoutView do
  use MehrSchulferienWeb, :view

  @doc """
  Determines whether to use Bootstrap CSS (legacy) or Tailwind CSS (new).

  Checks in the following order:
  1. View-specific preference in assigns[:css_framework]
  2. Global application config
  3. Defaults to Bootstrap (true) during migration
  """
  def use_bootstrap?(_conn, assigns) do
    cond do
      # Check if the current view has explicitly specified which CSS framework to use
      Map.has_key?(assigns, :css_framework) ->
        case assigns.css_framework do
          :bootstrap -> true
          :tailwind -> false
          :tailwind_new -> false
          # Default to bootstrap for unknown values
          _ -> true
        end

      # Fall back to application config
      Application.get_env(:mehr_schulferien, :css_framework) ->
        Application.get_env(:mehr_schulferien, :css_framework) == :bootstrap

      # Default to Bootstrap during the migration period
      true ->
        true
    end
  end

  @doc """
  Returns the appropriate layout template file based on the current CSS framework.
  """
  def select_layout_template(conn, assigns) do
    cond do
      Map.get(assigns, :css_framework) == :tailwind_new -> "app_tailwind_new.html"
      use_bootstrap?(conn, assigns) -> "app_bootstrap.html"
      true -> "app_tailwind.html"
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
