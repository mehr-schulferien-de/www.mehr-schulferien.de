defmodule MehrSchulferienWeb.PageHTML do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "page"

  # Basic view imports
  use PhoenixHTMLHelpers

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  # Import shared components for unified design
  import MehrSchulferienWeb.Shared.TypographyComponent
  import MehrSchulferienWeb.Shared.GridComponent
  import MehrSchulferienWeb.Shared.CardComponent
  import MehrSchulferienWeb.Shared.ButtonComponent

  alias MehrSchulferien.{Locations, BridgeDays, PeriodDisplay}
  alias MehrSchulferien.Calendars.DateHelpers

  def count_schools() do
    Locations.count_schools()
  end

  def get_school_period(periods) do
    PeriodDisplay.get_school_period(periods)
  end

  def display_period_info?(date, dates, period) do
    PeriodDisplay.display_period_info?(date, dates, period)
  end

  def get_period_colspan(date, last_date, period) do
    PeriodDisplay.get_period_colspan(date, last_date, period)
  end

  def show_period_info(period, colspan) do
    PeriodDisplay.show_period_info(period, colspan)
  end

  def get_non_school_period(date, period, periods) do
    PeriodDisplay.get_non_school_period(date, period, periods)
  end

  def best_bridge_day_teaser do
    BridgeDays.best_bridge_day_teaser()
  end

  def get_federal_state_periods(country, _federal_state, days) do
    first_day = List.first(days)
    last_day = List.last(days)

    # Filter relevant periods for the federal state
    country.periods
    |> Enum.filter(fn period ->
      Date.compare(period.ends_on, first_day) != :lt &&
        Date.compare(period.starts_on, last_day) != :gt
    end)
  end
end
