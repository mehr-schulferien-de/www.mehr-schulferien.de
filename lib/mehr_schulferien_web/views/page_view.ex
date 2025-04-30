defmodule MehrSchulferienWeb.PageView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferien.Locations

  def number_schools() do
    Locations.number_schools()
  end

  def get_school_period(periods) do
    case Enum.filter(periods, & &1.is_school_vacation) do
      [] -> nil
      [period] -> period
      periods -> select_display_period(periods)
    end
  end

  defp select_display_period(periods) do
    periods |> Enum.sort(&(&1.display_priority >= &2.display_priority)) |> hd
  end

  def display_period_info?(_, _, nil), do: false

  def display_period_info?(date, dates, period) do
    if period.is_school_vacation do
      if date == hd(dates) do
        true
      else
        date == period.starts_on
      end
    end
  end

  def get_period_colspan(date, last_date, period) do
    ends_on =
      if Date.compare(last_date, period.ends_on) == :gt do
        period.ends_on
      else
        last_date
      end

    Date.diff(ends_on, date) + 1
  end

  def show_period_info(period, colspan) do
    name = period.holiday_or_vacation_type.colloquial
    name_len = String.length(name)
    span = colspan * 4

    if name_len + 16 < span do
      "#{name} #{show_period_date(period)}"
    else
      if name_len < span do
        name
      else
        String.slice(name, 0, span)
      end
    end
  end

  defp show_period_date(period) do
    "(#{ViewHelpers.format_date_range(period.starts_on, period.ends_on, :short)})"
  end

  def get_non_school_period(_, nil, periods) do
    case Enum.filter(periods, &non_school_period/1) do
      [] -> nil
      [period] -> period
      periods -> select_display_period(periods)
    end
  end

  def get_non_school_period(date, period, periods) do
    if Date.compare(date, period.ends_on) == :gt do
      get_non_school_period(date, nil, periods)
    end
  end

  defp non_school_period(period) do
    period.holiday_or_vacation_type.name == "Wochenende" or period.is_school_vacation == false
  end

  def best_bridge_day_teaser do
    # Use NRW as the example (largest state)
    try do
      today = MehrSchulferien.Calendars.DateHelpers.today_berlin()
      current_year = today.year
      country = MehrSchulferien.Locations.get_country_by_slug!("d")
      federal_states = MehrSchulferien.Locations.list_federal_states(country)
      nrw = Enum.find(federal_states, &(&1.slug == "nordrhein-westfalen"))
      location_ids = [country.id, nrw.id]
      {:ok, start_date} = Date.new(current_year, 1, 1)
      {:ok, end_date} = Date.new(current_year, 12, 31)
      public_periods = MehrSchulferien.Periods.list_public_everybody_periods(location_ids, start_date, end_date)
      bridge_day_map = MehrSchulferien.Periods.group_by_interval(public_periods)
      best =
        List.flatten(Enum.map(bridge_day_map, fn {_k, v} -> v || [] end))
        |> Enum.max_by(fn bd ->
          periods = MehrSchulferien.Periods.list_periods_with_bridge_day(public_periods, bd)
          max_days = MehrSchulferienWeb.BridgeDayView.get_number_max_days(periods)
          percent = round((max_days - bd.number_days) / bd.number_days * 100)
          percent
        end, fn -> nil end)
      if best do
        periods = MehrSchulferien.Periods.list_periods_with_bridge_day(public_periods, best)
        max_days = MehrSchulferienWeb.BridgeDayView.get_number_max_days(periods)
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
