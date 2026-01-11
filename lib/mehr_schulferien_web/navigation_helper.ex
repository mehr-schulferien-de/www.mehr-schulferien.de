defmodule MehrSchulferienWeb.NavigationHelper do
  @moduledoc """
  Helper functions for navigation rendering.
  """

  @doc """
  Gets three years for navigation: current, next, and third year.
  Used for long-term vacation planning.
  """
  def get_navigation_years(today) do
    current_year = today.year
    next_year = current_year + 1
    third_year = current_year + 2
    {current_year, next_year, third_year}
  end

  @doc """
  Returns a list of federal states with their slugs and display names.
  """
  def federal_states do
    [
      {"baden-wuerttemberg", "Baden-Württemberg"},
      {"bayern", "Bayern"},
      {"berlin", "Berlin"},
      {"brandenburg", "Brandenburg"},
      {"bremen", "Bremen"},
      {"hamburg", "Hamburg"},
      {"hessen", "Hessen"},
      {"mecklenburg-vorpommern", "Mecklenburg-Vorpommern"},
      {"niedersachsen", "Niedersachsen"},
      {"nordrhein-westfalen", "Nordrhein-Westfalen"},
      {"rheinland-pfalz", "Rheinland-Pfalz"},
      {"saarland", "Saarland"},
      {"sachsen", "Sachsen"},
      {"sachsen-anhalt", "Sachsen-Anhalt"},
      {"schleswig-holstein", "Schleswig-Holstein"},
      {"thueringen", "Thüringen"}
    ]
  end

  @doc """
  Gets the display name for a federal state slug.
  """
  def federal_state_display_name(slug) do
    case List.keyfind(federal_states(), slug, 0) do
      {_, display_name} -> display_name
      nil -> slug
    end
  end
end
