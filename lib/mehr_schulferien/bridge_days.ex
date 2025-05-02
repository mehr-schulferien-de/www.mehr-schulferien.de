defmodule MehrSchulferien.BridgeDays do
  @moduledoc """
  Functions for calculating and handling bridge days.
  """

  alias MehrSchulferien.{Locations, Calendars.DateHelpers}
  alias MehrSchulferien.Periods.{Query, Grouping}
  alias MehrSchulferienWeb.BridgeDayView

  @doc """
  Returns whether a location has bridge days for a specific year.
  """
  def has_bridge_days?(location_ids, year) do
    MehrSchulferienWeb.BridgeDayController.has_bridge_days?(location_ids, year)
  end

  @doc """
  Calculates the best bridge day deal for teaser purposes.
  Uses NRW (largest state) as the example.
  """
  def best_bridge_day_teaser do
    try do
      today = DateHelpers.today_berlin()
      current_year = today.year
      country = Locations.get_country_by_slug!("d")
      federal_states = Locations.list_federal_states(country)
      north_rhine_westphalia = Enum.find(federal_states, &(&1.slug == "nordrhein-westfalen"))
      location_ids = [country.id, north_rhine_westphalia.id]
      {:ok, start_date} = Date.new(current_year, 1, 1)
      {:ok, end_date} = Date.new(current_year, 12, 31)
      public_periods = Query.list_public_everybody_periods(location_ids, start_date, end_date)
      bridge_day_map = Grouping.group_by_interval(public_periods)

      best_deal =
        List.flatten(Enum.map(bridge_day_map, fn {_k, v} -> v || [] end))
        |> Enum.max_by(
          fn bridge_day ->
            periods = Grouping.list_periods_with_bridge_day(public_periods, bridge_day)
            max_days = BridgeDayView.get_number_max_days(periods)
            percent = round((max_days - bridge_day.number_days) / bridge_day.number_days * 100)
            percent
          end,
          fn -> nil end
        )

      if best_deal do
        periods = Grouping.list_periods_with_bridge_day(public_periods, best_deal)
        max_days = BridgeDayView.get_number_max_days(periods)
        min_leave = best_deal.number_days
        percent = round((max_days - min_leave) / min_leave * 100)
        {percent, min_leave, max_days, current_year, best_deal.starts_on, best_deal.ends_on}
      else
        nil
      end
    rescue
      _ -> nil
    end
  end
end
