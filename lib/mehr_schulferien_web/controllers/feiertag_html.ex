defmodule MehrSchulferienWeb.FeiertagHTML do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "feiertag"

  # Basic view imports
  use PhoenixHTMLHelpers

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  # Import shared components for unified design
  import MehrSchulferienWeb.Shared.TypographyComponent
  import MehrSchulferienWeb.Shared.CardComponent

  @weekday_names %{
    1 => "Montag",
    2 => "Dienstag",
    3 => "Mittwoch",
    4 => "Donnerstag",
    5 => "Freitag",
    6 => "Samstag",
    7 => "Sonntag"
  }

  def weekday_name(date), do: @weekday_names[Date.day_of_week(date)]

  def weekend?(date), do: Date.day_of_week(date) > 5

  @doc "Number of holidays that fall on a Saturday or Sunday."
  def weekend_count(periods), do: Enum.count(periods, &weekend?(&1.starts_on))

  @doc "Short label for the states a national holiday row applies to."
  def states_label(states) when is_list(states) do
    Enum.map_join(states, ", ", & &1.name)
  end
end
