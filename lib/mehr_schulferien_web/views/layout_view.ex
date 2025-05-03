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
          _ -> true  # Default to bootstrap for unknown values
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
end
