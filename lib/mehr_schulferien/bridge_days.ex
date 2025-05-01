defmodule MehrSchulferien.BridgeDays do
  @moduledoc """
  Functions for calculating and handling bridge days.
  """

  alias MehrSchulferien.{Periods, Locations, Calendars.DateHelpers}
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
      nrw = Enum.find(federal_states, &(&1.slug == "nordrhein-westfalen"))
      location_ids = [country.id, nrw.id]
      {:ok, start_date} = Date.new(current_year, 1, 1)
      {:ok, end_date} = Date.new(current_year, 12, 31)
      public_periods = Periods.list_public_everybody_periods(location_ids, start_date, end_date)
      bridge_day_map = Periods.group_by_interval(public_periods)

      best =
        List.flatten(Enum.map(bridge_day_map, fn {_k, v} -> v || [] end))
        |> Enum.max_by(
          fn bd ->
            periods = Periods.list_periods_with_bridge_day(public_periods, bd)
            max_days = BridgeDayView.get_number_max_days(periods)
            percent = round((max_days - bd.number_days) / bd.number_days * 100)
            percent
          end,
          fn -> nil end
        )

      if best do
        periods = Periods.list_periods_with_bridge_day(public_periods, best)
        max_days = BridgeDayView.get_number_max_days(periods)
        min_leave = best.number_days
        percent = round((max_days - min_leave) / min_leave * 100)
        {percent, min_leave, max_days, current_year, best.starts_on, best.ends_on}
      else
        nil
      end
    rescue
      _ -> nil
    end
  end
end
