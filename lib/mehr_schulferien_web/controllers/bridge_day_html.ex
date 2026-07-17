defmodule MehrSchulferienWeb.BridgeDayHTML do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "bridge_day"

  # Basic view imports
  use PhoenixHTMLHelpers

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  alias MehrSchulferienWeb.ViewHelpers

  # Import shared components for unified design
  import MehrSchulferienWeb.Shared.TypographyComponent

  alias MehrSchulferien.BridgeDayCalculations
  alias MehrSchulferien.Calendars.DateHelpers

  @doc """
  SEO title for the federal state bridge day page. Leads with the number of
  bridge day opportunities because concrete numbers lift SERP click-through.
  """
  def bridge_day_page_title(federal_state, year, proposal_count) when proposal_count > 0 do
    "Brückentage #{federal_state.name} #{year}: #{proposal_count} Chancen für mehr Urlaub"
  end

  def bridge_day_page_title(federal_state, year, _proposal_count) do
    "Brückentage #{federal_state.name} #{year} - Clever Urlaub planen"
  end

  @doc """
  SEO meta description for the federal state bridge day page.
  """
  def bridge_day_page_description(federal_state, year, proposal_count)
      when proposal_count > 0 do
    "Die #{proposal_count} besten Brückentage #{year} in #{federal_state.name}: Termine mit Wochentag, nötige Urlaubstage und Gewinn an freien Tagen. Jetzt Urlaub clever planen."
  end

  def bridge_day_page_description(federal_state, year, _proposal_count) do
    "Brückentage #{year} in #{federal_state.name}: Feiertage, Termine und Tipps für die clevere Urlaubsplanung."
  end

  def format_month_header(start_date, end_date) do
    months_map = DateHelpers.get_months_map()
    first_month = start_date.month
    last_month = end_date.month
    first_year = start_date.year
    last_year = end_date.year

    cond do
      # Same month
      first_month == last_month ->
        months_map[first_month]

      # Multiple months, different years
      first_year != last_year ->
        first_month_abbr = String.at(months_map[first_month], 0) <> "."
        "#{first_month_abbr} #{first_year} #{months_map[last_month]} #{last_year}"

      # Multiple months, same year (use abbreviated format for first month)
      true ->
        first_month_abbr = String.at(months_map[first_month], 0) <> "."
        "#{first_month_abbr} #{months_map[last_month]}"
    end
  end

  defdelegate get_number_max_days(periods), to: BridgeDayCalculations

  defdelegate meets_minimum_gain?(bridge_day, periods), to: BridgeDayCalculations

  # NOTE: riverrun (2020-05-27)
  # This function is not being used because if a public holiday overlaps
  # with a weekend day, it is counted as a weekend day (and not a public
  # holiday) in the bridge day panel.
  def get_number_public_holidays(periods) do
    periods
    |> Enum.filter(& &1.is_public_holiday)
    |> calculate_number_days()
  end

  def get_number_weekend_days(periods) do
    periods
    |> Enum.filter(&(&1.holiday_or_vacation_type.name == "Wochenende"))
    |> calculate_number_days()
  end

  defp calculate_number_days(periods) do
    Enum.reduce(periods, 0, fn period, acc ->
      acc + Date.diff(period.ends_on, period.starts_on) + 1
    end)
  end

  def get_reference_date(conn) do
    DateHelpers.get_today_or_custom_date(conn)
  end
end
